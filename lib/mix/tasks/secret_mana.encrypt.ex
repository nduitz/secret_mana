defmodule Mix.Tasks.SecretMana.Encrypt do
  use Mix.Task

  @shortdoc "Encrypts a file using SecretMana for the given environment"

  @moduledoc """
  Encrypts a file using SecretMana for the given environment.

  ## Usage

      mix secret_mana.encrypt <env> <file>

  Where:

    * `<env>` is typically one of:
      * dev
      * test
      * prod

    * `<file>` is the path to the file you want to encrypt.

  The task will:

    * Ensure the `:secret_mana` application is started.
    * Build a `SecretMana.Config` for the given environment.
    * Invoke `SecretMana.encrypt/2` with the config and file path.

  ## Examples

      mix secret_mana.encrypt dev config/secrets.yml
      mix secret_mana.encrypt prod priv/secrets.txt

  ## Getting help

  You can show this help via:

      mix help secret_mana.encrypt

  Or by using:

      mix secret_mana.encrypt --help
      mix secret_mana.encrypt -h
  """

  @impl Mix.Task
  def run(args) do
    case parse_args(args) do
      {:ok, env, file} ->
        Application.ensure_all_started(:secret_mana)

        SecretMana.Config.new(env)
        |> SecretMana.encrypt(file)

      :help ->
        print_manual()

      {:error, message} ->
        Mix.shell().error(message)
        Mix.shell().info("")
        print_manual()
        Mix.raise("secret_mana.encrypt: invalid arguments")
    end
  end

  # Argument parsing

  defp parse_args(["-h"]), do: :help
  defp parse_args(["--help"]), do: :help

  defp parse_args([env, file])
       when is_binary(env) and env != "" and is_binary(file) and file != "" do
    {:ok, env, file}
  end

  defp parse_args([_env]) do
    {:error, "Missing required argument: <file>"}
  end

  defp parse_args([]) do
    {:error, "Missing required arguments: <env> <file>"}
  end

  defp parse_args(_args) do
    {:error, "Too many arguments were provided."}
  end

  # Manual / help text

  defp print_manual do
    Mix.shell().info("""
    SecretMana Encrypt

    Usage:
        mix secret_mana.encrypt <env> <file>

    Arguments:
        <env>     The environment to use (e.g. dev, test, prod)
        <file>    The path to the file to encrypt

    Examples:
        mix secret_mana.encrypt dev config/secrets.yml
        mix secret_mana.encrypt test priv/credentials.txt
        mix secret_mana.encrypt prod priv/secrets.env

    For more information:
        mix help secret_mana.encrypt
    """)
  end
end
