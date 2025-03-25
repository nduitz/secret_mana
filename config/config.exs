import Config

config :secret_mana, otp_app: :secret_mana

config :secret_mana, SecretMana.AgeBackend,
  binary: "age",
  keygen_binary: "age-keygen"
