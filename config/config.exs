# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

# Configures the endpoint
config :esad, EsadWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "tNQWTiVv1BcDb8GfCsVAVt4y9OcnGlDPF1z2MPlpooiZO9eXpbJkmVGUpFL2qmD/",
  render_errors: [view: EsadWeb.ErrorView, accepts: ~w(html json)],
  pubsub_server: Esad.PubSub

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

config :esad, Esad.HttpPollerEndpoint,
  endpoint: {"https://randommer.io/Number", "LowerRange=1&HigherRange=1000&range=range1&X-Requested-With=XMLHttpRequest"}

config :esad, Esad.EventStream,
  interval_size: 10,
  threshold_value: 20,
  stream_timeout: 20_000

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
