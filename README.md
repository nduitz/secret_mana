<!-- @format -->

# SecretMana

A collection of mix tasks to interact with [age](https://github.com/FiloSottile/age).
Inspired by rails credential management. Born from frustration of desync secrets.

Thanks to [@FiloSottile](https://github.com/FiloSottile/age) for building age <3.

And thanks to the maintainers of [phoenixframework/tailwind](https://github.com/phoenixframework/tailwind/) which I leaned on heavily while implementing this <3.

## Disclaimer

This isn't currently well tested (only on mac). I will try to upgrade this as soon as I am able to test on different platforms.

## Installation

```elixir
def deps do
  [
    {:secret_mana, "~> 0.0.1"}
  ]
end
```

## Usage

### Configuration

```
config :secret_mana,
    backend: SecretMana.AgeBackend,
    otp_app: :my_app

config :secret_mana, SecretMana.AgeBackend,
  version: "1.2.1" # default: "1.2.1", used to specify version installed
  local_install: true/false # default: "true"; if false installation is always skipped. Then you can either manually set `bin_dir` or let the backend handle the finding of the binaries (by using which/where).
  Useful to bundle binaries in deployments
  bin_dir: "my_bin_path" # see `local_install`
  secret_base_path: "config/custom_secrets_folder" # default: "config/secrets"; path SecretMana will put files in, useful to scope for different environments
  key_file: "my.key" # default: "age.key"; used to rename key-file; stored under base_path
  pub_key_file: "my.key.pub" # default: "age.pub"; used to rename pub-key-file; stored under base_path
  encrypted_file: "secret.enc" # default: "age.enc"; used to rename secret-file; stored under base_path
  file_type: :yaml # default: :json; currently only json and yaml are supported,
  binary: "age" # default: "age", only required if binary name differs from default
  key_generator_binary: "age-keygen" # default: "age-keygen", only required if keygen-binary name differs from default,
```

### Mix Tasks

`mix secret_mana.install` - install

`mix secret_mana.gen.key <env>` - generates a new key pair depending on your config

`mix secret_mana.encrypt <env> <file>` - encrypts a given json/yaml file and stores it accordingly to your config

`EDITOR="code --wait" mix secret_mana.edit <env>` - allows editing your secrets (falls back to `vim`)

### Reading your secrets

Its as simple as this:

```
# read all secrets
SecretMana.read!()

# read specific secret
SecretMana.read!(["foo", "bar"])
```

Note: `read!` will raise an error if the requested key is not found, with helpful information about available keys.

## License

Copyright (c) 2025 Nick Duitz.

age source code is licensed under the [BSD 3-Clause "New" or "Revised" License](https://github.com/FiloSottile/age/blob/main/LICENSE).
