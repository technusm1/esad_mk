defmodule Esad.Event do
  @moduledoc """
  Represent a event for a specific point of time

  """

  defstruct stream: nil, datetime: nil, value: nil, tags: nil
end
