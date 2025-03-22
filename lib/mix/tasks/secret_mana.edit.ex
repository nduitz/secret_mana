defmodule Mix.Tasks.SecretMana.Edit do
  use Mix.Task

  @impl Mix.Task
  def run(_) do
    SecretMana.edit()
  end
end
