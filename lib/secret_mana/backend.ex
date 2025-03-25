defmodule SecretMana.Backend do
  @moduledoc """
  The backend behaviour for the SecretMana library.
  """

  @type config :: %SecretMana.Config{}
  @type file_path :: String.t()
  @type key_path :: list(String.t())

  @callback config(config()) :: config()
  @callback install(config()) :: :ok
  @callback encrypt(config(), file_path(), check_file_type :: boolean()) :: :ok
  @callback decrypt(config(), String.t()) :: :ok
  @callback gen_key(config()) :: :ok
  @callback edit(config()) :: :ok
  @callback read(config(), key_path()) :: term()
  @callback download_url(config()) :: String.t()

  @optional_callbacks [
    download_url: 1
  ]

  defmacro __using__(_) do
    quote do
      @behaviour SecretMana.Backend

      require Logger
    end
  end
end
