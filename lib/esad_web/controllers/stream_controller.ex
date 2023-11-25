defmodule EsadWeb.StreamController do
  alias Esad.EventStream
  use EsadWeb, :controller

  def list(conn, _params) do
    render(conn, "index.html", streams: streams())
  end


  def stream(conn, %{"stream" => stream_id}) do
    stream = Map.get(streams(), stream_id)
    render(conn, "stream.html", stream_id: stream_id, stream: stream)
  end


  def streams() do
    EventStream.get_list_of_streams()
    |> Enum.into(%{}, fn stream_id -> {stream_id, EventStream.metric!(stream_id)} end)
  end
end
