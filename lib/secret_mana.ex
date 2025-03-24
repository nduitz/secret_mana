defmodule SecretMana do
  @moduledoc """
  SecretMana is a module for managing encrypted secrets using age (https://github.com/FiloSottile/age).

  This module provides functionality to:
  - Read encrypted secrets
  - Edit secrets with your preferred editor
  - Encrypt/decrypt files
  - Generate age keys
  - Install the age binary

  SecretMana supports both JSON and YAML formats for secret files.
  """

  use Application

  defmacro __using__(_) do
    quote do
      Application.ensure_all_started(:secret_mana)
    end
  end

  def start(_, _) do
    Supervisor.start_link([], strategy: :one_for_one)
  end

  @doc """
  Reads and decrypts secrets from the configured secret file.

  ## Parameters
    * `path` - Optional list of keys to traverse the secret structure, defaults to nil which returns the entire secret

  ## Examples
      # Read all secrets
      SecretMana.read()

      # Read a specific nested key
      SecretMana.read(["database", "password"])
  """
  def read(config, access_path \\ nil) do
    apply(config.backend, :read, [config, access_path])
  end

  @doc """
  Opens the decrypted secrets in your editor for modification, then re-encrypts them when done.

  Uses the EDITOR environment variable to determine which editor to use, falls back to vim if not set.

  ## Examples
      SecretMana.edit()
  """
  def edit(config) do
    apply(config.backend, :edit, [config])
  end

  @doc """
  Encrypts a file using the age public key.

  The file must be in the format specified by the configuration (JSON or YAML).

  ## Parameters
    * `file` - Path to the file to encrypt

  ## Examples
      SecretMana.encrypt("secrets.json")
  """
  def encrypt(config, file, check_file_type \\ true) do
    apply(config.backend, :encrypt, [config, file, check_file_type])
  end

  @doc """
  Generates a new age key pair in the configured directory.

  Creates both a private key file and a public key file.

  ## Examples
      SecretMana.gen_key()
  """
  def gen_key(config) do
    apply(config.backend, :gen_key, [config])
  end

  @doc """
  Downloads and installs the age binary for the current platform.

  Automatically detects the correct version based on the current system architecture.

  ## Examples
      SecretMana.install()
  """
  def install(config) do
    apply(config.backend, :install, [config])
  end
end
