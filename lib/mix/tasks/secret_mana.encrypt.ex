defmodule Mix.Tasks.SecretMana.Encrypt do
  use Mix.Task

  @impl Mix.Task
  def run(args) do
    Application.ensure_all_started(:secret_mana)

    args
    |> List.first()
    |> then(fn file ->
      if file do
        SecretMana.Config.new()
        |> SecretMana.encrypt(file)
      else
        raise """
        Usage: mix secret_mana.encrypt <file>
        """
      end
    end)
  end
end
