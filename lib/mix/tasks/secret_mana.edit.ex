defmodule Mix.Tasks.SecretMana.Edit do
  use Mix.Task
  use SecretMana.Config

  @impl Mix.Task
  def run(_) do
    SecretMana.edit(@secret_mana_config)
  end
end
