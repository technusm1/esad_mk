defmodule Esad.Application do
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      %{
        id: Esad.StreamProcessRegistry,
        start: {Esad.StreamProcessRegistry, :start_link, []}
      },
      {DynamicSupervisor, name: Esad.EventStreamDynamicSupervisor, strategy: :one_for_one},
      EsadWeb.Endpoint,
      {Esad.HttpPollerEndpoint, interval: 10},
      {Phoenix.PubSub, [name: Esad.PubSub, adapter: Phoenix.PubSub.PG2]}
    ]

    opts = [strategy: :one_for_one, name: Esad.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    EsadWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
