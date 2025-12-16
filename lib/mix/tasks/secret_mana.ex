defmodule Mix.Tasks.SecretMana do
  use Mix.Task

  @shortdoc "Lists available SecretMana Mix tasks"

  @moduledoc """
  A small index task for the SecretMana Mix tasks.

  ## Usage

      mix secret_mana

  This will print a short overview of all available `secret_mana.*` tasks
  and how to get more detailed help.

  For detailed information on a specific task, use:

      mix help secret_mana.install
      mix help secret_mana.edit
      mix help secret_mana.encrypt
      mix help secret_mana.gen.key
  """

  @impl Mix.Task
  def run(_args) do
    Mix.shell().info("""
    SecretMana Mix tasks
    ====================

    Configuration / Setup
      mix secret_mana.install <env>
          Installs SecretMana for the given environment.

      mix secret_mana.edit <env>
          Opens the SecretMana configuration for editing.

      mix secret_mana.gen.key <env>
          Generates a SecretMana key for the given environment.

    Encryption
      mix secret_mana.encrypt <env> <file>
          Encrypts a file using SecretMana for the given environment.

    Usage hints
      • <env> is typically one of: dev, test, prod
      • Use --help or -h on any task for a short usage reminder:
            mix secret_mana.install --help
            mix secret_mana.encrypt -h
    """)
  end
end
