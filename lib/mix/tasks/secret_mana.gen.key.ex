defmodule Mix.Tasks.SecretMana.Gen.Key do
  use Mix.Task
  use SecretMana.Config

  @impl Mix.Task
  def run(_opts) do
    SecretMana.gen_key(@secret_mana_config)
  end
end
