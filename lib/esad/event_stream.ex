defmodule Esad.EventStream do
  @moduledoc """
  Consume a stream of event and do some analytics

  The event stream should manage multiple "logical" streams
  which can be idenitifed by it's source. The source can be
  a unique identifier for a remote endpoint or an internal
  reference.

  Speficially it's required that the input for each individual
  source is processed in order, it should be able to detect the
  below conditions for any given source and should be able to
  produce minimal metrics for

  * Value differs by more than ±40%
  * Value above/below threshold for `n` periods

  For any source that has not received any data for a configurable
  time period it's state should be removed.
  """

  require Logger
  alias Esad.StreamState
  alias Esad.EventStream
  alias Esad.StreamProcessRegistry

  use GenServer, restart: :transient

  defp via_tuple(id) do
    StreamProcessRegistry.via_tuple({__MODULE__, id})
  end

  defp get_interval_size() do
    Application.get_env(:esad, __MODULE__)[:interval_size] || 10
  end

  defp get_threshold_value() do
    Application.get_env(:esad, __MODULE__)[:threshold_value] || 20
  end

  defp get_stream_timeout() do
    Application.get_env(:esad, __MODULE__)[:stream_timeout] || 20_000
  end

  defp whereis(id) do
    case StreamProcessRegistry.whereis_name({__MODULE__, id}) do
      :undefined -> nil
      pid -> {:ok, pid}
    end
  end

  def start_link(id) do
    GenServer.start_link(__MODULE__, id, name: via_tuple(id))
  end

  @doc """
  Process the incoming event for a particular source.

  If the source does not exist it should be created automatically
  """
  def input(%Esad.Event{stream: stream_id} = stream_event) when not is_nil(stream_id) do
    {:ok, stream_pid} =
      whereis(stream_id) ||
        DynamicSupervisor.start_child(Esad.EventStreamDynamicSupervisor, {EventStream, stream_id})

    stream_event =
      Map.update!(stream_event, :datetime, fn value ->
        value || DateTime.utc_now()
      end)

    GenServer.cast(stream_pid, {:event_input, stream_event})
  end

  @doc """
  Retrieve metrics for the given source

  Returns data in the form:

  %StreamState{
    outputs: [....],
    inputs: [...],
    hourly_error_rate: ...
  }

  Should raise an error if metric is not found.
  """
  def metric!(stream_id) do
    {:ok, stream_pid} = whereis(stream_id) || raise RuntimeError, message: "stream not found"
    GenServer.call(stream_pid, :get_metrics)
  end

  @doc """
  Stop the given stream
  """
  def stop(stream_id) do
    with {:ok, stream_pid} <- whereis(stream_id) do
      GenServer.stop(stream_pid, :normal)
    end
  end

  def get_list_of_streams() do
    # get a list of keys
    Registry.select(StreamProcessRegistry, [{{:"$1", :_, :_}, [], [:"$1"]}])
    |> Enum.map(fn {Esad.EventStream, stream_id} -> stream_id end)
  end

  @impl true
  def init(id) do
    # The state is a tuple containing the following:
    # - StreamState: The state of the event stream (visible to the user)
    # - The event_timeout timer: The timer will add an error to the output of the state when an event is not received within a given time limit.
    {:ok, {%StreamState{id: id}, nil}, get_stream_timeout()}
  end

  @impl true
  def handle_info(:timeout, {state, timer}) do
    unless is_nil(timer) do
      Process.cancel_timer(timer)
    end
    Logger.info("Stream #{state.id} didn't receive any events within the given timeout of #{get_stream_timeout()} milliseconds. Closing now.")
    {:stop, :normal, {state, nil}}
  end

  @impl true
  def handle_info({:event_input_timeout, event_timeout}, {state, timer}) do
    unless is_nil(timer) do
      Process.cancel_timer(timer)
    end
    Logger.info("Stream #{state.id} didn't receive any events within 1.5x interval, will add an error to outputs.")
    outputs = Map.get(state, :outputs, [])
    error_event = %Esad.Event{stream: state.id, datetime: DateTime.utc_now(), value: "Event not received in 1.5x interval", tags: ["error"]}
    {:noreply, {%{state | outputs: [error_event | outputs]}, nil}, get_stream_timeout() - event_timeout}
  end

  @impl true
  def handle_cast({:event_input, stream_event}, {%StreamState{} = state, timer}) do
    unless is_nil(timer) do
      Process.cancel_timer(timer)
    end
    inputs = Map.get(state, :inputs, [])
    state_with_metrics = calculate_metrics(stream_event, state)
    event_timeout = if length(inputs) >= 1 do
      previous_event_datetime = List.first(inputs).datetime
      latest_event_datetime = stream_event.datetime
      DateTime.diff(latest_event_datetime, previous_event_datetime, :millisecond) * 1.5 |> round()
    else
      get_stream_timeout()
    end
    if event_timeout < get_stream_timeout() do
      event_timer = Process.send_after(self(), {:event_input_timeout, event_timeout}, event_timeout)
      {:noreply, {%{state_with_metrics | inputs: [stream_event | inputs]}, event_timer}, get_stream_timeout()}
    else
      {:noreply, {%{state_with_metrics | inputs: [stream_event | inputs]}, nil}, get_stream_timeout()}
    end
  end

  @impl true
  def handle_call(:get_metrics, _from, {%StreamState{error_count: error_count} = state, timer}) do
    hourly_error_rate =
      if length(state.inputs) >= 2 do
        {latest_event_datetime, earliest_event_datetime} =
          {List.first(state.inputs).datetime, List.last(state.inputs).datetime}

        error_count * 3600 / DateTime.diff(latest_event_datetime, earliest_event_datetime)
      else
        0
      end
    stats = %{hourly_error_rate: hourly_error_rate, inputs: length(state.inputs), outputs: length(state.outputs)}
    state = %{state | stats: stats}
    {:reply, state, {state, timer}, get_stream_timeout()}
  end

  defp calculate_metrics(_event, %StreamState{inputs: []} = state_so_far) do
    state_so_far
  end

  defp calculate_metrics(
         event,
         %StreamState{inputs: [previous_input | _remaining_inputs]} = state_so_far
       ) do
    error_count =
      if abs(event.value - previous_input.value) / previous_input.value > 0.4 do
        1
      else
        0
      end

    error_count =
      error_count +
        if length(state_so_far.inputs) >= get_interval_size() do
          if(
            state_so_far.inputs
            |> Stream.take(get_interval_size())
            |> Enum.all?(fn event -> event.value < get_threshold_value() end) or
              state_so_far.inputs
              |> Stream.take(get_interval_size())
              |> Enum.all?(fn event -> event.value > get_threshold_value() end),
            do: 1,
            else: 0
          )
        else
          0
        end

    %{state_so_far | error_count: state_so_far.error_count + error_count}
  end
end
