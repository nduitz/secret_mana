defmodule Mix.Tasks.SecretMana.Edit do
  use Mix.Task

  @shortdoc "Edits SecretMana configuration for the given environment"

  @moduledoc """
  Opens the SecretMana configuration for editing for a given environment.

  ## Usage

      mix secret_mana.edit <env>

  Where `<env>` is typically one of:

    * dev
    * test
    * prod

  The task will:

    * Ensure the `:secret_mana` application is started.
    * Build a `SecretMana.Config` for the given environment.
    * Invoke `SecretMana.edit/1` with the config.

  ## Examples

      mix secret_mana.edit dev
      mix secret_mana.edit prod

  ## Getting help

  You can display this help with:

      mix help secret_mana.edit

  Or by using:

      mix secret_mana.edit --help
      mix secret_mana.edit -h
  """

  @impl Mix.Task
  def run(args) do
    case parse_args(args) do
      {:ok, env} ->
        Application.ensure_all_started(:secret_mana)

        SecretMana.Config.new(env)
        |> SecretMana.edit()

      :help ->
        print_manual()

      {:error, message} ->
        Mix.shell().error(message)
        Mix.shell().info("")
        print_manual()
        Mix.raise("secret_mana.edit: invalid arguments")
    end
  end

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

  defp print_manual do
    Mix.shell().info("""
    SecretMana Editor

    Usage:
        mix secret_mana.edit <env>

    Arguments:
        <env>    The environment whose configuration to edit (e.g. dev, test, prod)

    Examples:
        mix secret_mana.edit dev
        mix secret_mana.edit test
        mix secret_mana.edit prod

    For more information:
        mix help secret_mana.edit
    """)
  end
end
