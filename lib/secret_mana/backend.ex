defmodule SecretMana.Backend do
  @moduledoc """
  The backend behaviour for the SecretMana library.
  """

  @type config :: %SecretMana.Config{}
  @type file_path :: String.t()
  @type key_path :: list(String.t())

  @callback config(config()) :: config()
  @callback install(config()) :: :ok | {:error, String.t()}
  @callback encrypt(config(), file_path(), check_file_type :: boolean()) ::
              :ok | {:error, String.t()}
  @callback decrypt(config(), String.t()) ::
              :ok | {:error, String.t()}
  @callback gen_key(config()) :: :ok | {:error, String.t()}
  @callback edit(config()) :: :ok | {:error, String.t()}
  @callback read(config(), key_path()) :: {:ok, map()} | {:error, String.t()}
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
