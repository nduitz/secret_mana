defmodule SecretMana.Config do
  @public_config_keys [
    backend: SecretMana.AgeBackend,
    otp_app: nil
  ]
  @private_config_keys [
    backend_config: nil,
    runtime: false
  ]
  defstruct Keyword.merge(@public_config_keys, @private_config_keys)

  defmacro __using__(opts) do
    {invalid_config_keys, config} =
      :secret_mana
      |> Application.get_all_env()
      |> Keyword.split(@public_config_keys)

    {runtime, []} = Keyword.pop(opts, :runtime, false)

    config = Keyword.merge(config, runtime: runtime)

    unless invalid_config_keys == [] do
      raise """
        Invalid configuration keys: #{inspect(invalid_config_keys)}
      """
    end

    quote do
      Module.put_attribute(
        __MODULE__,
        :secret_mana_config,
        SecretMana.Config.new(unquote(config))
      )
    end
  end

  def new(config) do
    struct(__MODULE__, config)
    |> put_backend_config
  end

  defp put_backend_config(config) do
    %__MODULE__{config | backend_config: apply(config.backend, :config, [config])}
  end
end
