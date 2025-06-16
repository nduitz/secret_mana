defmodule Mix.Tasks.SecretMana.Install do
  use Mix.Task

  @impl Mix.Task
  def run(_opts) do
    Application.ensure_all_started(:secret_mana)

    SecretMana.Config.new()
    |> SecretMana.install()
  end
end
