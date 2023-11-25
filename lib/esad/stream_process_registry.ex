defmodule Esad.StreamProcessRegistry do
  def via_tuple(key) when is_tuple(key) do
    {:via, Registry, {__MODULE__, key}}
  end

  def whereis_name(key) when is_tuple(key) do
    Registry.whereis_name({__MODULE__, key})
  end

  def start_link() do
    Registry.start_link(keys: :unique, name: __MODULE__)
  end
end
