import Config

# Do not print debug messages in production
config :logger, level: :info

config :secret_mana, SecretMana.AgeBackend,
  local_install: false

# Runtime production configuration, including reading
# of environment variables, is done on config/runtime.exs.
