defmodule SecretMana.Config do
  @latest_version "1.2.1"

  def version() do
    Application.get_env(:secret_mana, :version, @latest_version)
  end

  def local_install() do
    Application.get_env(:secret_mana, :local_install, true)
  end

  def bin_dir() do
    local_install()
    |> if do
      name = "age-#{version()}"

      Path.expand("_build/#{name}/")
    else
      Application.fetch_env!(:secret_mana, :bin_dir)
    end
  end

  def age_bin_path() do
    Path.join([bin_dir(), "age"])
  end

  def age_keygen_bin_path() do
    Path.join([bin_dir(), "age-keygen"])
  end

  def default_base_url do
    "https://github.com/FiloSottile/age/releases/download/v$version/age-v$version-$target"
  end

  def file_type() do
    Application.get_env(:secret_mana, :file_type, :json)
  end

  def default_base_path() do
    Path.expand("config/")
  end

  def base_path() do
    Application.get_env(:secret_mana, :base_path, default_base_path())
  end

  def default_key_file() do
    "age.key"
  end

  def key_file() do
    Path.join([base_path(), Application.get_env(:secret_mana, :key_file, default_key_file())])
  end

  def default_pub_key_file() do
    "age.pub"
  end

  def pub_key_file() do
    Path.join([
      base_path(),
      Application.get_env(:secret_mana, :pub_key_file, default_pub_key_file())
    ])
  end

  def default_secret_file() do
    "age.enc"
  end

  def secret_file() do
    Path.join([
      base_path(),
      Application.get_env(:secret_mana, :secret_file, default_secret_file())
    ])
  end

  def target() do
    arch_str = :erlang.system_info(:system_architecture)
    target_triple = arch_str |> List.to_string() |> String.split("-")

    {arch, abi} =
      case target_triple do
        [arch, _vendor, _system, abi] -> {arch, abi}
        [arch, _vendor, abi] -> {arch, abi}
        [arch | _] -> {arch, nil}
      end

    case {:os.type(), arch, abi, :erlang.system_info(:wordsize) * 8} do
      {{:win32, _}, _arch, _abi, 64} ->
        "windows-amd64.zip"

      {{:unix, :darwin}, arch, _abi, 64} when arch in ~w(arm aarch64) ->
        "darwin-arm64.tar.gz"

      {{:unix, :darwin}, "x86_64", _abi, 64} ->
        "darwin-amd64.tar.gz"

      {{:unix, _osname}, arch, _abi, 64} when arch in ~w(x86_64 amd64) ->
        "linux-amd64.tar.gz"

      {_os, _arch, _abi, _wordsize} ->
        raise "Not yet implemented or unsupported"
    end
  end

  def protocol_versions do
    if otp_version() < 25, do: [:"tlsv1.2"], else: [:"tlsv1.2", :"tlsv1.3"]
  end

  def otp_version do
    :erlang.system_info(:otp_release) |> List.to_integer()
  end
end
