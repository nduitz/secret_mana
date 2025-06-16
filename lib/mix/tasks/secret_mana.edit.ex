defmodule Mix.Tasks.SecretMana.Edit do
  use Mix.Task

  @impl Mix.Task
  def run(_) do
    Application.ensure_all_started(:secret_mana)

    SecretMana.Config.new()
    |> SecretMana.edit()
  end
end
