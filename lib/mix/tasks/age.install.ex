defmodule Mix.Tasks.Age.Install do
  use Mix.Task

  def run(_opts) do
    SecretMana.install()
  end
end
