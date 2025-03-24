defmodule Mix.Tasks.SecretMana.Install do
  use Mix.Task
  use SecretMana.Config

  @impl Mix.Task
  def run(_opts) do
    SecretMana.install(@secret_mana_config)
  end
end
