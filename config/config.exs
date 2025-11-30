# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :kantox,
  ecto_repos: [Kantox.Repo],
  generators: [timestamp_type: :utc_datetime]

# Configures the endpoint
config :kantox, KantoxWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [json: KantoxWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: Kantox.PubSub

# Configures the mailer
#
# By default it uses the "Local" adapter which stores the emails
# locally.
#
# For production it's recommended to configure a different adapter
# at the `config/runtime.exs`.
config :kantox, Kantox.Mailer, adapter: Swoosh.Adapters.Local

# Configures Elixir's Logger
config :logger, :default_formatter,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# PhoenixSwagger configuration (only for serving Swagger UI)
config :phoenix_swagger, json_library: Jason

# Hammer rate limiter configuration
config :hammer,
  backend:
    {Hammer.Backend.ETS,
     [expiry_ms: 60_000 * 60 * 2, cleanup_interval_ms: 60_000 * 10]}

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
