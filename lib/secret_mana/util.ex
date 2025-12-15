defmodule SecretMana.Util do
  require Logger

  def open_editor_with_tmp_file(nil, tmp_file) do
    System.cmd("vim", [tmp_file], use_stdio: false)
  end

  def open_editor_with_tmp_file(editor_command, tmp_file) do
    [editor_bin | editor_args] = String.split(editor_command, " ")

    System.cmd(editor_bin, editor_args ++ [tmp_file])
  end

  def check_file_type(file, file_type) do
    file_ext = Path.extname(file)

    cond do
      file_type == :json && file_ext == ".json" ->
        file
        |> File.read!()
        |> Jason.decode!()

      file_type == :yaml && (file_ext == ".yaml" || file_ext == ".yml") ->
        YamlElixir.read_from_file!(file)

      true ->
        raise """
        Unsupported file type, only JSON and YAML files are supported.
        Make sure config and file extensions match:

        config: #{file_type}
        extension: #{file_ext}
        """
    end
  end

  def fetch_body!(url, retry \\ true) do
    url = String.to_charlist(url)
    Logger.debug("Downloading backend from #{url}")

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
        Backend couldn't be found at: #{url}

        This could mean that you're trying to install a version that does not support the detected
        target architecture.
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
        you might manually download the executable from the URL above and place it in the configured bin directory.
        """
    end
  end

  defp fallback(:inet), do: :inet6
  defp fallback(:inet6), do: :inet

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
        :windows_amd_64

      {{:unix, :darwin}, arch, _abi, 64} when arch in ~w(arm aarch64) ->
        :darwin_arm_64

      {{:unix, :darwin}, "x86_64", _abi, 64} ->
        :darwin_amd_64

      {{:unix, _osname}, arch, _abi, 64} when arch in ~w(x86_64 amd64) ->
        :linux_amd_64

      {{:unix, _osname}, arch, _abi, 64} when arch in ~w(arm aarch64) ->
        :linux_arm_64

      {_os, _arch, _abi, _wordsize} ->
        raise "Not yet implemented or unsupported"
    end
  end

  def protocol_versions do
    if otp_version() < 25, do: [:"tlsv1.2"], else: [:"tlsv1.2", :"tlsv1.3"]
  end

  defp otp_version do
    :erlang.system_info(:otp_release) |> List.to_integer()
  end
end
