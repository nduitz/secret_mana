defmodule SecretMana.Config do
  @public_config_keys [
    backend: SecretMana.AgeBackend,
    otp_app: nil,
    release: false
  ]
  @private_config_keys [
    backend_config: nil
  ]
  defstruct Keyword.merge(@public_config_keys, @private_config_keys)

  def new() do
    {invalid_config_keys, config} =
      :secret_mana
      |> Application.get_all_env()
      |> Keyword.split(@public_config_keys)

    unless invalid_config_keys == [] do
      raise """
        Invalid configuration keys: #{inspect(invalid_config_keys)}
      """
    end

    struct(__MODULE__, config)
    |> put_backend_config
  end

  defp put_backend_config(config) do
    %__MODULE__{config | backend_config: apply(config.backend, :config, [config])}
  end
end
