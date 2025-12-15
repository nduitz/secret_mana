defmodule SecretManaTest do
  use ExUnit.Case
  doctest SecretMana

  import ExUnit.CaptureLog

  @json_test_file "test/test_files/test.json"
  @yaml_test_file "test/test_files/test.yaml"
  describe "read/1" do
    test "reads and decodes JSON secrets" do
      json_content = ~s({"api_key": "secret123", "nested": {"value": "nested_secret"}})

      setup_age()
      |> gen_secret()
      |> encrypt_secret(json_content)

      result = SecretMana.read!()
      assert result == %{"api_key" => "secret123", "nested" => %{"value" => "nested_secret"}}

      # Test with path
      assert SecretMana.read!(["nested", "value"]) == "nested_secret"
    end

    test "reads and decodes YAML secrets" do
      yaml_content = """
      api_key: secret123
      nested:
        value: nested_secret
      """

      setup_age([], file_type: :yaml)
      |> gen_secret()
      |> encrypt_secret(yaml_content)

      # Test without path
      result = SecretMana.read!()
      assert result == %{"api_key" => "secret123", "nested" => %{"value" => "nested_secret"}}

      # Test with path
      assert SecretMana.read!(["nested", "value"]) == "nested_secret"
    end
  end

  describe "edit/1" do
    test "opens editor and re-encrypts file" do
      json_content = ~s({"test": "value"})

      config =
        setup_age()
        |> gen_secret()
        |> encrypt_secret(json_content)

      System.put_env("EDITOR", "echo")

      assert SecretMana.edit(config) == :ok
      assert SecretMana.read!() == Jason.decode!(json_content)
    end
  end

  describe "encrypt/3" do
    test "encrypts JSON file" do
      config =
        setup_age()
        |> gen_secret()

      assert SecretMana.encrypt(config, @json_test_file) == :ok
      assert SecretMana.read!() == Jason.decode!(File.read!(@json_test_file))
    end

    test "encrypts YAML file" do
      config =
        setup_age([], file_type: :yaml)
        |> gen_secret()

      assert SecretMana.encrypt(config, @yaml_test_file) == :ok
      assert SecretMana.read!() == YamlElixir.read_from_file!(@yaml_test_file)
    end

    test "raises error when public key is missing" do
      config =
        setup_age()
        |> gen_secret()

      File.rm!(config.backend_config.absolute_pub_key_file_path)

      assert_raise RuntimeError, ~r/Public key not found/, fn ->
        SecretMana.encrypt(config, "test.json")
      end
    end

    test "raises error for mismatched file type" do
      config =
        setup_age()
        |> gen_secret()

      File.write!("test.yaml", "test: value")

      assert_raise RuntimeError, ~r/Unsupported file type/, fn ->
        SecretMana.encrypt(config, "test.yaml")
      end

      File.rm!("test.yaml")
    end
  end

  describe "gen_key/1" do
    test "generates key files" do
      config = setup_age()

      assert SecretMana.gen_key(config) == :ok
      assert File.exists?(config.backend_config.absolute_key_file_path)

      File.rm!(config.backend_config.absolute_key_file_path)
    end
  end

  describe "install/1" do
    test "skips installation local install is disabled" do
      config = setup_age([], local_install: false)

      log =
        capture_log(fn ->
          assert SecretMana.install(config) == :ok
        end)

      assert log =~ "Local install disabled."
    end

    test "installs age when not already installed" do
      config = setup_age([], local_install: true)

      log =
        capture_log(fn ->
          assert SecretMana.install(config) == :ok
        end)

      assert log =~ "Installing age..."
      assert log =~ "Installation complete"

      File.rm_rf!(config.backend_config.absolute_bin_dir_path)
    end
  end

  defp setup_age(base_config \\ [], backend_config \\ []) do
    backend_config = Keyword.merge([local_install: false], backend_config)
    put_base_config(base_config)
    put_backend_config(:age, backend_config)

    SecretMana.Config.new()
  end

  defp gen_secret(config) do
    SecretMana.gen_key(config)

    config
  end

  defp encrypt_secret(config, content) do
    file =
      case config.backend_config.file_type do
        :json -> secrets_file(:json, content)
        :yaml -> secrets_file(:yaml, content)
      end

    SecretMana.encrypt(config, file)

    config
  end

  defp secrets_file(file_type, content) do
    {:ok, tmp_file} = Briefly.create(extname: ".#{file_type}")

    File.write!(tmp_file, content)

    on_exit(fn ->
      File.rm!(tmp_file)
    end)

    tmp_file
  end

  defp put_base_config(values) do
    config =
      [
        backend: SecretMana.AgeBackend,
        otp_app: :secret_mana
      ]
      |> Keyword.merge(values)

    Application.put_all_env(secret_mana: config)
  end

  defp put_backend_config(:age, values) do
    version = "1.2.1"
    target = SecretMana.Util.target()
    # Create temporary directory for tests
    {:ok, tmp_dir} = Briefly.create(type: :directory)

    on_exit(fn ->
      # Cleanup tmp directory after tests
      File.rm_rf!(tmp_dir)
    end)

    config =
      [
        version: version,
        bin_dir: Path.join(["test", "binaries", "age-#{version}", "#{target}"]) |> Path.expand(),
        file_type: :json,
        secret_base_path: tmp_dir,
        key_file: "age.key",
        pub_key_file: "age.pub",
        encrypted_file: "age.enc",
        binary: "age",
        key_generator_binary: "age-keygen"
      ]
      |> Keyword.merge(values)

    Application.put_env(:secret_mana, SecretMana.AgeBackend, config)
  end
end
