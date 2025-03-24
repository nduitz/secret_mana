defmodule SecretMana.AgeBackend do
  use SecretMana.Backend
  require Logger

  @latest_version "1.2.1"

  @public_config_keys [
    version: @latest_version,
    local_install: true,
    bin_dir: nil,
    file_type: :json,
    secret_base_path: "config/",
    key_file: "age.key",
    pub_key_file: "age.pub",
    encrypted_file: "age.enc",
    string_identity_file: nil,
    binary: "age",
    key_generator_binary: "age-keygen"
  ]
  @private_config_keys [
    use_otp_path: false,
    absolute_bin_dir_path: nil,
    absolute_age_bin_path: nil,
    absolute_absolute_age_keygen_bin_path: nil,
    absolute_base_path: nil,
    absolute_key_file_path: nil,
    absolute_pub_key_file_path: nil,
    absolute_encrypted_file_path: nil
  ]
  defstruct Keyword.merge(@public_config_keys, @private_config_keys)

  @impl true
  def config(base_config) do
    config = Application.get_env(:secret_mana, __MODULE__)

    struct(__MODULE__, config)
    |> put_absolute_bin_dir_path(base_config.release)
    |> put_absolute_age_bin_path()
    |> put_absolute_age_keygen_bin_path()
    |> put_absolute_base_path(base_config.release)
    |> put_abolute_key_file_path()
    |> put_abolute_pub_key_file_path()
    |> put_abolute_encrypted_file_path()
  end

  @impl true
  def install(config) do
    %{local_install: local_install, absolute_bin_dir_path: absolute_bin_dir_path} =
      config.backend_config

    if local_install do
      File.mkdir_p!(absolute_bin_dir_path)

      File.ls!(absolute_bin_dir_path)
      |> then(fn files ->
        Enum.all?(["age", "age-keygen"], fn expected_file ->
          expected_file in files
        end)
      end)
      |> case do
        true ->
          Logger.info("age already installed")

        false ->
          do_install(config)
      end
    else
      Logger.info("Local install disabled. age should be installed in `#{absolute_bin_dir_path}`")
    end

    :ok
  end

  defp do_install(config) do
    Logger.info("Installing age...")

    url = download_url(config)
    body = SecretMana.Util.fetch_body!(url)

    extract_binaries(config, body)

    Logger.info("Installation complete...")
  end

  @impl true
  def read(config, access_path) do
    %{
      absolute_age_bin_path: absolute_age_bin_path,
      absolute_encrypted_file_path: absolute_encrypted_file_path,
      file_type: file_type
    } = config.backend_config

    secrets =
      with_file_secret(config, fn key_file_path ->
        {secrets, _} =
          System.cmd(absolute_age_bin_path, [
            "-d",
            "-i",
            key_file_path,
            absolute_encrypted_file_path
          ])

        secrets
      end)

    result =
      case file_type do
        :json -> Jason.decode!(secrets)
        :yaml -> YamlElixir.read_from_string!(secrets)
      end

    case access_path do
      access_path when is_list(access_path) ->
        get_in(result, access_path)

      nil ->
        result

      _ ->
        raise """
        Invalid path, please provide a list of keys to traverse the secret.
        Example: ["key", "subkey"]
        """
    end
  end

  @impl true
  def edit(config) do
    editor = System.get_env("EDITOR")

    {temp_file, _} = System.cmd("mktemp", [])
    temp_file = String.trim(temp_file)

    decrypt(config, temp_file)

    SecretMana.Util.open_editor_with_temp_file(editor, temp_file)

    encrypt(config, temp_file, false)

    File.rm!(temp_file)

    :ok
  end

  @impl true
  def decrypt(config, path) do
    %{
      absolute_age_bin_path: absolute_age_bin_path,
      absolute_encrypted_file_path: absolute_encrypted_file_path
    } = config.backend_config

    with_file_secret(config, fn key_file_path ->
      System.cmd(absolute_age_bin_path, [
        "-d",
        "-i",
        key_file_path,
        "-o",
        path,
        absolute_encrypted_file_path
      ])
    end)
  end

  defp with_file_secret(config, fun) do
    %{
      absolute_key_file_path: absolute_key_file_path,
      string_identity_file: string_identity_file
    } =
      config.backend_config

    if string_identity_file do
      {temp_file, _} = System.cmd("mktemp", [])
      temp_file = String.trim(temp_file)
      File.write!(temp_file, string_identity_file, [:binary])
      File.chmod(temp_file, 0o600)

      result = fun.(temp_file)

      File.rm_rf!(temp_file)

      result
    else
      fun.(absolute_key_file_path)
    end
  end

  @impl true
  def encrypt(config, file_path, check_file_type) do
    %{
      absolute_age_bin_path: absolute_age_bin_path,
      absolute_pub_key_file_path: absolute_pub_key_file_path,
      absolute_encrypted_file_path: absolute_encrypted_file_path,
      file_type: file_type
    } = config.backend_config

    File.exists?(absolute_pub_key_file_path) or
      raise """
      Public key not found, please generate secret key first or define path.

      Usage: mix secret_mana.gen.key
      """

    if check_file_type, do: SecretMana.Util.check_file_type(file_path, file_type)

    {_, 0} =
      System.cmd(
        absolute_age_bin_path,
        [
          "-o",
          absolute_encrypted_file_path,
          "-R",
          absolute_pub_key_file_path,
          file_path
        ]
      )

    :ok
  end

  @impl true
  def gen_key(config) do
    %{
      absolute_absolute_age_keygen_bin_path: absolute_absolute_age_keygen_bin_path,
      absolute_key_file_path: absolute_key_file_path,
      absolute_pub_key_file_path: absolute_pub_key_file_path,
      absolute_base_path: absolute_base_path
    } = config.backend_config

    System.cmd("mkdir", ["-p", absolute_base_path])

    System.cmd(absolute_absolute_age_keygen_bin_path, ["-o", absolute_key_file_path])

    {pub_key, _} =
      System.cmd(absolute_absolute_age_keygen_bin_path, ["-y", absolute_key_file_path])

    File.write!(absolute_pub_key_file_path, pub_key, [:binary])
  end

  @impl true
  def download_url(config) do
    base_url = default_base_url()
    get_url(config, base_url)
  end

  defp extract_binaries(config, body) do
    %{
      absolute_bin_dir_path: absolute_bin_dir_path,
      absolute_age_bin_path: absolute_age_bin_path,
      absolute_absolute_age_keygen_bin_path: absolute_absolute_age_keygen_bin_path
    } = config.backend_config

    {temp_dir, _} = System.cmd("mktemp", ["-d"])
    temp_dir = String.trim(temp_dir)

    case SecretMana.Util.target() do
      "windows-amd64.zip" ->
        Application.ensure_all_started(:erl_tar)

        :zip.extract(body, cwd: temp_dir)

      _ ->
        Application.ensure_all_started(:erl_tar)

        :erl_tar.extract({:binary, body}, [:compressed, cwd: temp_dir])
    end

    File.mkdir_p!(absolute_bin_dir_path)

    File.cp!(Path.join([temp_dir, "age", "age"]), absolute_age_bin_path)

    File.cp!(
      Path.join([temp_dir, "age", "age-keygen"]),
      absolute_absolute_age_keygen_bin_path
    )

    File.chmod(absolute_age_bin_path, 0o755)
    File.chmod(absolute_absolute_age_keygen_bin_path, 0o755)

    File.rm_rf!(temp_dir)
  end

  defp default_base_url do
    "https://github.com/FiloSottile/age/releases/download/v$version/age-v$version-$target"
  end

  defp get_url(config, base_url) do
    target = SecretMana.Util.target()
    version = config.backend_config.version

    base_url
    |> String.replace("$version", version)
    |> String.replace("$target", target)
  end

  defp put_absolute_bin_dir_path(config, use_otp_path) do
    %__MODULE__{config | absolute_bin_dir_path: absolute_bin_dir_path(config, use_otp_path)}
  end

  defp absolute_bin_dir_path(config, use_otp_path) do
    %__MODULE__{version: version, local_install: local_install} = config

    bin_dir =
      if local_install do
        name = "age-#{version}"

        "_build/#{name}/"
      else
        !!config.bin_dir or
          raise """
            The `bin_dir` configuration is required when `local_install` is set to false.
          """

        config.bin_dir
      end

    if use_otp_path do
      Application.app_dir(config.otp_app, bin_dir)
    else
      Path.expand(bin_dir)
    end
  end

  defp put_absolute_age_bin_path(config) do
    %__MODULE__{config | absolute_age_bin_path: absolute_age_bin_path(config)}
  end

  defp absolute_age_bin_path(config) do
    Path.join([config.absolute_bin_dir_path, config.binary])
  end

  defp put_absolute_age_keygen_bin_path(config) do
    %__MODULE__{
      config
      | absolute_absolute_age_keygen_bin_path: absolute_absolute_age_keygen_bin_path(config)
    }
  end

  defp absolute_absolute_age_keygen_bin_path(config) do
    Path.join([config.absolute_bin_dir_path, config.key_generator_binary])
  end

  defp put_absolute_base_path(config, use_otp_path) do
    %__MODULE__{config | absolute_base_path: absolute_base_path(config, use_otp_path)}
  end

  defp absolute_base_path(config, use_otp_path) do
    if use_otp_path do
      Application.app_dir(config.otp_app, config.secret_base_path)
    else
      Path.expand(config.secret_base_path)
    end
  end

  defp put_abolute_key_file_path(config) do
    %__MODULE__{config | absolute_key_file_path: absolute_key_file_path(config)}
  end

  defp absolute_key_file_path(config) do
    Path.join([config.absolute_base_path, config.key_file])
  end

  defp put_abolute_pub_key_file_path(config) do
    %__MODULE__{config | absolute_pub_key_file_path: absolute_pub_key_file_path(config)}
  end

  defp absolute_pub_key_file_path(config) do
    Path.join([config.absolute_base_path, config.pub_key_file])
  end

  defp put_abolute_encrypted_file_path(config) do
    %__MODULE__{config | absolute_encrypted_file_path: absolute_encrypted_file_path(config)}
  end

  defp absolute_encrypted_file_path(config) do
    Path.join([config.absolute_base_path, config.encrypted_file])
  end
end
