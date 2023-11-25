defmodule Esad.StreamState do
  @moduledoc """
  This is the state of the stream that will be shown to the end-users.
  """
  defstruct id: nil, inputs: [], outputs: [], stats: %{}, error_count: 0
end
