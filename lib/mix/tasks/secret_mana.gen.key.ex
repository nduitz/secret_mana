defmodule Mix.Tasks.SecretMana.Gen.Key do
  use Mix.Task

  @impl Mix.Task
  def run(_opts) do
    Application.ensure_all_started(:secret_mana)

    SecretMana.Config.new()
    |> SecretMana.gen_key()
  end
end
