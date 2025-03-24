defmodule Mix.Tasks.SecretMana.Edit do
  use Mix.Task

  @impl Mix.Task
  def run(_) do
    SecretMana.Config.new()
    |> SecretMana.edit()
  end
end
