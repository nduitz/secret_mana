defmodule SecretMana.Config do
  @public_config_keys [
    backend: SecretMana.AgeBackend,
    otp_app: nil,
    environment: nil
  ]
  @private_config_keys [
    backend_config: nil
  ]
  defstruct Keyword.merge(@public_config_keys, @private_config_keys)

  def new() do
    all_config = Application.get_all_env(:secret_mana)
    config_keys = Keyword.keys(@public_config_keys)

    # Extract valid config and check for invalid keys
    valid_config = Keyword.take(all_config, config_keys)
    invalid_keys = all_config |> Keyword.keys() |> Enum.reject(&(&1 in config_keys))

    # Filter out backend-specific configs (they're handled separately)
    backend_modules = [SecretMana.AgeBackend]
    invalid_keys = Enum.reject(invalid_keys, &(&1 in backend_modules))

    unless invalid_keys == [] do
      raise """
        Invalid configuration keys: #{inspect(invalid_keys)}
      """
    end

    # Merge defaults with provided config
    final_config = Keyword.merge(@public_config_keys, valid_config)

    struct(__MODULE__, final_config)
    |> put_backend_config
  end

  defp put_backend_config(config) do
    %__MODULE__{config | backend_config: apply(config.backend, :config, [config])}
  end
end
