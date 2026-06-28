# This file is responsible for configuring your umbrella
# and **all applications** and their dependencies with the
# help of the Config module.
#
# Note that all applications in your umbrella share the
# same configuration and dependencies, which is why they
# all use the same configuration file. If you want different
# configurations or dependencies per app, it is best to
# move said applications out of the umbrella.
import Config

config :trenurang_core, ecto_repos: [Trenurang.Repo]

config :trenurang_core, Trenurang.Repo,
  username: System.get_env("DB_USERNAME", "postgres"),
  password: System.get_env("DB_PASSWORD", "postgres"),
  hostname: System.get_env("DB_HOSTNAME", "localhost"),
  database: System.get_env("DB_NAME", "trenurang_dev"),
  pool_size: 10,
  types: Trenurang.PostgresTypes

if config_env() == :test do
  config :trenurang_core, Trenurang.Repo,
    pool: Ecto.Adapters.SQL.Sandbox,
    log: false
end
