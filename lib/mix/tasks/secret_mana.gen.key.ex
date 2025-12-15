defmodule Mix.Tasks.SecretMana.Gen.Key do
  use Mix.Task

  @shortdoc "Generates a SecretMana key for the given environment"

  @moduledoc """
  Generates a SecretMana key for the given environment.

  ## Usage

      mix secret_mana.gen.key <env>

  Where `<env>` is typically one of:

    * dev
    * test
    * prod

  The task will:

    * Ensure the `:secret_mana` application is started.
    * Build a `SecretMana.Config` for the given environment.
    * Invoke `SecretMana.gen_key/1` with the config.

  ## Examples

      mix secret_mana.gen.key dev
      mix secret_mana.gen.key prod

  ## Getting help

  You can show this help via:

      mix help secret_mana.gen.key

  Or by using:

      mix secret_mana.gen.key --help
      mix secret_mana.gen.key -h
  """

  @impl Mix.Task
  def run(args) do
    case parse_args(args) do
      {:ok, env} ->
        Application.ensure_all_started(:secret_mana)

        SecretMana.Config.new(env)
        |> SecretMana.gen_key()

      :help ->
        print_manual()

      {:error, message} ->
        Mix.shell().error(message)
        Mix.shell().info("")
        print_manual()
        Mix.raise("secret_mana.gen.key: invalid arguments")
    end
  end

  # Argument parsing

  defp parse_args(["-h"]), do: :help
  defp parse_args(["--help"]), do: :help

  defp parse_args([env]) when is_binary(env) and env != "" do
    {:ok, env}
  end

  defp parse_args([]) do
    {:error, "Missing required argument: <env>"}
  end

  defp parse_args(_args) do
    {:error, "Too many arguments were provided."}
  end

  # Manual / help text

  defp print_manual do
    Mix.shell().info("""
    SecretMana Key Generator

    Usage:
        mix secret_mana.gen.key <env>

    Arguments:
        <env>    The environment to generate a key for (e.g. dev, test, prod)

    Examples:
        mix secret_mana.gen.key dev
        mix secret_mana.gen.key test
        mix secret_mana.gen.key prod

    For more information:
        mix help secret_mana.gen.key
    """)
  end
end
