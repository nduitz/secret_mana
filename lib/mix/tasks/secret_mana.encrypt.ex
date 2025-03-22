defmodule Mix.Tasks.SecretMana.Encrypt do
  use Mix.Task

  @impl Mix.Task
  def run(args) do
    args
    |> List.first()
    |> then(fn file ->
      if file do
        SecretMana.encrypt(file)
      else
        raise """
        Usage: mix secret_mana.encrypt <file>
        """
      end
    end)
  end
end
