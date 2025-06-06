defmodule SecretMana do
  @moduledoc """
  SecretMana is a module for managing encrypted secrets build to support various backends.
  Currently only age (https://github.com/FiloSottile/age) is supported.

  This module is a wrapper for the `SecretMana.Backend`:
  - Read encrypted secrets with support for nested key access
  - Edit secrets using your preferred editor
  - Encrypt/decrypt files in supported formats
  - Generate keys for storing secrets
  - Install backend

  ## Examples
      # Read all secrets
      secrets = SecretMana.read(config)

      # Read a specific nested key
      password = SecretMana.read(config, ["database", "password"])

      # Edit secrets in your preferred editor
      :ok = SecretMana.edit(config)

      # Encrypt a new secrets file
      :ok = SecretMana.encrypt(config, "new_secrets.json")

      # Generate a new key pair
      :ok = SecretMana.gen_key(config)

      # Install age binary
      :ok = SecretMana.install(config)
  """

  use Application

  def start(_, _) do
    Supervisor.start_link([], strategy: :one_for_one)
  end

  @doc """
  Reads and decrypts secrets from the configured secret file.

  ## Parameters
    * `config` - The SecretMana configuration struct
    * `access_path` - Optional list of keys to traverse the secret structure, defaults to nil which returns the entire secret

  ## Returns
    * `term()` - The decrypted secrets

  ## Examples
      # Read all secrets
      secrets = SecretMana.read(config)

      # Read a specific nested key
      password = SecretMana.read(config, ["database", "password"])
  """
  defmacro read!(access_path \\ nil) do
    quote do
      config = SecretMana.Config.new()

      apply(config.backend, :read!, [config, unquote(access_path)])
    end
  end

  @doc """
  Opens the decrypted secrets in your editor for modification, then re-encrypts them when done.

  Uses the EDITOR environment variable to determine which editor to use, falls back to vim if not set.

  ## Parameters
    * `config` - The SecretMana configuration struct

  ## Returns
    * `:ok` - Successfully edited and re-encrypted secrets

  ## Examples
      :ok = SecretMana.edit(config)
  """
  def edit(config) do
    apply(config.backend, :edit, [config])
  end

  @doc """
  Encrypts a file using the age public key.

  The file must be in the format specified by the configuration (JSON or YAML).

  ## Parameters
    * `config` - The SecretMana configuration struct
    * `file` - Path to the file to encrypt
    * `check_file_type` - Whether to validate the file format matches the configured format, defaults to true

  ## Returns
    * `:ok` - Successfully encrypted the file

  ## Examples
      :ok = SecretMana.encrypt(config, "secrets.json")
      :ok = SecretMana.encrypt(config, "secrets.json", false)
  """
  def encrypt(config, file, check_file_type \\ true) do
    apply(config.backend, :encrypt, [config, file, check_file_type])
  end

  @doc """
  Generates a new age key pair in the configured directory.

  Creates both a private key file and a public key file.

  ## Parameters
    * `config` - The SecretMana configuration struct

  ## Returns
    * `:ok` - Successfully generated key pair

  ## Examples
      :ok = SecretMana.gen_key(config)
  """
  def gen_key(config) do
    apply(config.backend, :gen_key, [config])
  end

  @doc """
  Downloads and installs the age binary for the current platform.

  Automatically detects the correct version based on the current system architecture.

  ## Parameters
    * `config` - The SecretMana configuration struct

  ## Returns
    * `:ok` - Successfully installed age binary

  ## Examples
      :ok = SecretMana.install(config)
  """
  def install(config) do
    apply(config.backend, :install, [config])
  end

  @doc """
  Sets the private key for age encryption at runtime.

  This function allows you to configure the private key dynamically at runtime,
  typically called from runtime.exs. This is more secure than embedding the
  private key in the release artifact.

  ## Parameters
    * `private_key` - The private key content as a string

  ## Returns
    * `:ok` - Successfully configured the private key

  ## Examples
      # In runtime.exs
      SecretMana.generate_private_key_file(System.get_env("SECRET_MANA_PRIVATE_KEY"))
  """
  def generate_private_key_file(private_key) do
    config = SecretMana.Config.new()

    apply(config.backend, :generate_private_key_file, [config, private_key])
  end

  @doc """
  Release step function that copies secrets from development directories into the release.

  This function can be used as a release step in mix.exs to automatically
  copy encrypted secrets and keys from secrets/<env>/ into the release's config/secrets/
  directory during the build process. Only the target environment's secrets are copied
  to avoid including secrets from other environments in the release.

  ## Security Note:

  For enhanced security, set `embed_private_key?` to `false` and use the runtime configuration
  approach with `SecretMana.AgeBackend.put_private_key/1` in runtime.exs instead of
  embedding the private key in the release artifact.

  ## Usage in mix.exs:

      # Option 1: Include private key in release (less secure)
      def project do
        [
          # ... other config
          releases: [
            my_app: [
              steps: [:assemble, &SecretMana.copy_secrets_for_release/1]
            ]
          ]
        ]
      end

      # Option 2: Exclude private key from release (more secure)
      def project do
        [
          # ... other config
          releases: [
            my_app: [
              steps: [:assemble, fn release ->
                SecretMana.copy_secrets_for_release(release, false)
              end]
            ]
          ]
        ]
      end

  ## Runtime Configuration (when embed_private_key? is false):

      # runtime.exs - Option 1: Using SecretMana module
      SecretMana.put_private_key(System.get_env("SECRET_MANA_PRIVATE_KEY"))

      # runtime.exs - Option 2: Using AgeBackend directly
      SecretMana.AgeBackend.put_private_key(System.get_env("SECRET_MANA_PRIVATE_KEY"))

  ## Directory Structure:

      # Development:
      config/secrets/dev/age.key
      config/secrets/dev/age.pub
      config/secrets/dev/age.enc

      # Release (when embed_private_key? is true):
      lib/my_app-x.x.x/config/secrets/age.key
      lib/my_app-x.x.x/config/secrets/age.pub
      lib/my_app-x.x.x/config/secrets/age.enc

      # Release (when embed_private_key? is false):
      lib/my_app-x.x.x/config/secrets/age.pub
      lib/my_app-x.x.x/config/secrets/age.enc

  ## Parameters
    * `release` - The Mix.Release struct
    * `embed_private_key?` - Whether to include the private key in the release (defaults to false for security)

  ## Returns
    * `release` - The unmodified release struct (following release step convention)
  """
  def copy_secrets_for_release(release, embed_private_key? \\ false) do
    config = SecretMana.Config.new()
    %{backend_config: %{secret_base_path: secret_base_path, key_file: key_file}} = config

    # Get the release target environment (e.g., :prod)
    release_env = release.options[:env] || Mix.env()
    target_env = to_string(release_env)

    # Source directory (development) - only the target environment
    source_dir = Path.join([secret_base_path, target_env]) |> Path.expand()

    # Destination directory (release) - config/secrets (no environment subdirectory)
    dest_dir =
      Path.join([
        release.path,
        "lib",
        "#{release.name}-#{release.version}",
        "config",
        "secrets"
      ])

    if File.exists?(source_dir) do
      File.mkdir_p!(dest_dir)

      if embed_private_key? do
        File.cp_r!(source_dir, dest_dir)

        IO.puts(
          "SecretMana: Copied #{release_env} secrets to release (including private key file)"
        )
      else
        copy_secrets_excluding_private_key(source_dir, dest_dir, key_file)

        IO.puts(
          "SecretMana: Copied #{release_env} secrets to release (private key excluded for security)"
        )
      end
    else
      IO.puts("SecretMana: No secrets found in #{source_dir} - skipping")
    end

    # Always return the release unchanged
    release
  end

  defp copy_secrets_excluding_private_key(source_dir, dest_dir, key_file) do
    for file <- File.ls!(source_dir) do
      source_path = Path.join(source_dir, file)
      dest_path = Path.join(dest_dir, file)

      cond do
        File.dir?(source_path) ->
          File.mkdir_p!(dest_path)
          copy_secrets_excluding_private_key(source_path, dest_path, key_file)

        file != key_file ->
          File.cp!(source_path, dest_path)

        true ->
          :skip
      end
    end
  end
end
