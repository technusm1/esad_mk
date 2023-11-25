defmodule Esad.HttpPollerEndpoint do
  @moduledoc """
  Get value from remote endpoint on a fixed interval
  """

  use GenServer

  require Logger

  def start_link(opts) do
    {name, arg} = Keyword.pop(opts, :name, __MODULE__)
    GenServer.start_link(__MODULE__, arg, name: name)
  end


  @doc """
  Trigger an immediate poll of the remote endpoint
  """
  def poll(pid), do: GenServer.cast(pid, :poll)

  @impl true
  def init(cfg) do
    {initial_state, cfg} = Keyword.pop(cfg, :state)
    {interval, _cfg} = Keyword.pop(cfg, :interval)


    {:ok, tref} = :timer.send_interval(interval * 1000, :poll)

    Logger.info("Starting http poller with interval := #{interval}s")

    {:ok,
     %{
       timer: tref,
       state: initial_state
     }}
  end

  @impl true
  def handle_cast(:poll, state) do
    next_state = on_interval(state)
    {:noreply, next_state}
  end

  @impl true
  def handle_info(:poll, state) do
    next_state = on_interval(state)
    {:noreply, next_state}
  end


  defp on_interval(state) do
    {endpoint, body} = Application.get_env(:esad, __MODULE__)[:endpoint]

    requested = DateTime.utc_now()

    # poll the API
    headers = [{"content-type", "application/x-www-form-urlencoded"}]

    %{status_code: 200, body: body} = HTTPoison.post! endpoint, body, headers

    ev = %Esad.Event{
      stream: "#{__MODULE__}_#{Enum.random(1..3)}",
      datetime: requested,
      value: String.to_integer(body)
    }

    Logger.info "Received #{inspect ev}"

    :ok = Esad.EventStream.input(ev)

    state
  end



end
