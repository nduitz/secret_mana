defmodule Mix.Tasks.SecretMana.Encrypt do
  use Mix.Task
  use SecretMana.Config

  @impl Mix.Task
  def run(args) do
    args
    |> List.first()
    |> then(fn file ->
      if file do
        SecretMana.encrypt(@secret_mana_config, file)
      else
        raise """
        Usage: mix secret_mana.encrypt <file>
        """
      end
    end)
  end
end
