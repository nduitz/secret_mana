defmodule SecretMana do
  @moduledoc """
  SecretMana is a module for managing encrypted secrets using age (https://github.com/FiloSottile/age).

  This module provides functionality to:
  - Read encrypted secrets
  - Edit secrets with your preferred editor
  - Encrypt/decrypt files
  - Generate age keys
  - Install the age binary

  SecretMana supports both JSON and YAML formats for secret files.
  """

  require Logger
  import SecretMana.Config

  @doc """
  Reads and decrypts secrets from the configured secret file.

  ## Parameters
    * `path` - Optional list of keys to traverse the secret structure, defaults to nil which returns the entire secret

  ## Examples
      # Read all secrets
      SecretMana.read()

      # Read a specific nested key
      SecretMana.read(["database", "password"])
  """
  def read(path \\ nil) do
    {secrets, _} = System.cmd(age_bin_path(), ["-d", "-i", key_file(), secret_file()])

    result =
      case file_type() do
        :json -> Jason.decode!(secrets)
        :yaml -> YamlElixir.read_from_string!(secrets)
      end

    case path do
      path when is_list(path) ->
        get_in(result, path)

      nil ->
        result

      _ ->
        raise """
        Invalid path, please provide a list of keys to traverse the secret.
        Example: ["key", "subkey"]
        """
    end
  end

  @doc """
  Opens the decrypted secrets in your editor for modification, then re-encrypts them when done.

  Uses the EDITOR environment variable to determine which editor to use, falls back to vim if not set.

  ## Examples
      SecretMana.edit()
  """
  def edit() do
    editor = System.get_env("EDITOR")
    {temp_file, _} = System.cmd("mktemp", [])
    temp_file = String.trim(temp_file)
    System.cmd(age_bin_path(), ["-d", "-o", temp_file, "-i", key_file(), secret_file()])

    run_editor(editor, temp_file)

    encrypt(temp_file)
    File.rm!(temp_file)
  end

  defp run_editor(editor_command, temp_file)

  defp run_editor(nil, temp_file) do
    port = Port.open({:spawn, "vim #{temp_file}"}, [:nouse_stdio, :exit_status])

    receive do
      {^port, {:exit_status, _exit_status}} ->
        # all done
        nil
    end
  end

  defp run_editor(editor_command, temp_file) do
    [editor_bin | editor_args] = String.split(editor_command, " ")

    System.cmd(editor_bin, editor_args ++ [temp_file])
  end

  @doc """
  Encrypts a file using the age public key.

  The file must be in the format specified by the configuration (JSON or YAML).

  ## Parameters
    * `file` - Path to the file to encrypt

  ## Examples
      SecretMana.encrypt("secrets.json")
  """
  def encrypt(file) do
    File.exists?(pub_key_file()) or
      raise """
      Public key not found, please generate secret key first or define path.

      Usage: mix age.gen.key
      """

    file_ext = Path.extname(file)

    cond do
      file_type() == :json && file_ext == ".json" ->
        file
        |> File.read!()
        |> Jason.decode!()

      file_type() == :yaml && (file_ext == ".yaml" || file_ext == ".yml") ->
        YamlElixir.read_from_file!(file)

      true ->
        raise """
        Unsupported file type, only JSON and YAML files are supported.
        Make sure config and file extensions match:

        config: #{file_type()}
        extension: #{file_ext}
        """
    end

    System.cmd(
      age_bin_path(),
      [
        "-o",
        secret_file(),
        "-R",
        pub_key_file(),
        file
      ]
    )
  end

  @doc """
  Generates a new age key pair in the configured directory.

  Creates both a private key file and a public key file.

  ## Examples
      SecretMana.gen_key()
  """
  def gen_key() do
    System.cmd("mkdir", ["-p", base_path()])

    System.cmd(age_keygen_bin_path(), ["-o", key_file()])
    {pub_key, _} = System.cmd(age_keygen_bin_path(), ["-y", key_file()])
    File.write!(pub_key_file(), pub_key, [:binary])
  end

  @doc """
  Downloads and installs the age binary for the current platform.

  Automatically detects the correct version based on the current system architecture.

  ## Examples
      SecretMana.install()
  """
  def install() do
    bin_dir = bin_dir()

    if File.exists?(bin_dir) do
      Logger.info("age already installed")
    else
      Logger.info("Installing age...")

      base_url = default_base_url()
      url = get_url(base_url)
      body = fetch_body!(url)

      extract_binaries(body)

      Logger.info("Installation complete...")
    end
  end

  defp fetch_body!(url, retry \\ true) do
    url = String.to_charlist(url)
    Logger.debug("Downloading age from #{url}")

    {:ok, _} = Application.ensure_all_started(:inets)
    {:ok, _} = Application.ensure_all_started(:ssl)

    http_options =
      [
        ssl: [
          verify: :verify_peer,
          cacerts: :public_key.cacerts_get(),
          depth: 2,
          customize_hostname_check: [
            match_fun: :public_key.pkix_verify_hostname_match_fun(:https)
          ],
          versions: protocol_versions()
        ]
      ]

    options = [body_format: :binary]

    case {retry, :httpc.request(:get, {url, []}, http_options, options)} do
      {_, {:ok, {{_, 200, _}, _headers, body}}} ->
        body

      {_, {:ok, {{_, 404, _}, _headers, _body}}} ->
        raise """
        The age binary couldn't be found at: #{url}

        This could mean that you're trying to install a version that does not support the detected
        target architecture.

        You can see the available files for the configured version at:

        https://github.com/FiloSottile/age/releases/tag/v#{version()}
        """

      {true, {:error, {:failed_connect, [{:to_address, _}, {inet, _, reason}]}}}
      when inet in [:inet, :inet6] and
             reason in [:ehostunreach, :enetunreach, :eprotonosupport, :nxdomain] ->
        :httpc.set_options(ipfamily: fallback(inet))
        fetch_body!(to_string(url), false)

      other ->
        raise """
        Couldn't fetch #{url}: #{inspect(other)}

        This typically means we cannot reach the source or you are behind a proxy.
        You can try again later and, if that does not work,
        you might manually download the executable from the URL above and
        place it inside "_build/age-#{version()}".
        """
    end
  end

  defp fallback(:inet), do: :inet6
  defp fallback(:inet6), do: :inet

  defp extract_binaries(body) do
    case target() do
      "windows-amd64.zip" ->
        Application.ensure_all_started(:erl_tar)

        :zip.extract(body)

      _ ->
        Application.ensure_all_started(:erl_tar)

        :erl_tar.extract({:binary, body}, [:compressed, cwd: bin_dir()])
    end
  end

  defp get_url(base_url) do
    base_url
    |> String.replace("$version", version())
    |> String.replace("$target", target())
  end
end
