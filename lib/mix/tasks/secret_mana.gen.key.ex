defmodule Mix.Tasks.SecretMana.Gen.Key do
  use Mix.Task

  @impl Mix.Task
  def run(_opts) do
    SecretMana.Config.new()
    |> SecretMana.gen_key()
  end
end
