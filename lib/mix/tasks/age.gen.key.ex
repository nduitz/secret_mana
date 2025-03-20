defmodule Mix.Tasks.Age.Gen.Key do
  use Mix.Task

  def run(_opts) do
    SecretMana.gen_key()
  end
end
