defmodule Mix.Tasks.Age.Encrypt do
  def run(args) do
    args
    |> List.first()
    |> then(fn file ->
      if file do
        SecretMana.encrypt(file)
      else
        raise """
        Usage: mix age.encrypt <file>
        """
      end
    end)
  end
end
