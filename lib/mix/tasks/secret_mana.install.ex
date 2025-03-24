defmodule Mix.Tasks.SecretMana.Install do
  use Mix.Task

  @impl Mix.Task
  def run(_opts) do
    SecretMana.Config.new()
    |> SecretMana.install()
  end
end
