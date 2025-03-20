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
  version: "1.2.1" # default: "1.2.1", used to specify version installed
  base_path: "config/prod" # default: "config"; path SecretMana will put files in, useful to scope for different environments
  key_file: "my.key" # default: "age.key"; used to rename key-file; stored under base_path
  pub_key_file: "my.key.pub" # default: "age.pub"; used to rename pub-key-file; stored under base_path
  secret_file: "secret.enc" # default: "age.enc"; used to rename secret-file; stored under base_path
  file_type: :yaml # default: :json; currently only json and yaml are supported
```

### Mix Tasks

`mix age.install` - install

`mix age.gen.key` - generates a new key pair depending on your config

`mix age.encrypt file` - encrypts a given json/yaml file and stores it accordingly to your config

`EDITOR="code --wait" mix age.edit` - allows editing your secrets (falls back to `vim`)

### Reading your secrets

Its as simple as this:

```
# read all secrets
SecretMana.read()

# read specific secret
SecretMana.read(["foo", "bar"])
```

## License

Copyright (c) 2025 Nick Duitz.

age source code is licensed under the [BSD 3-Clause "New" or "Revised" License](https://github.com/FiloSottile/age/blob/main/LICENSE).
