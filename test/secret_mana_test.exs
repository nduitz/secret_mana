defmodule SecretManaTest do
  use ExUnit.Case
  doctest SecretMana

  import ExUnit.CaptureLog
  import Mock

  setup do
    # Create temporary directory for tests
    tmp_dir = System.tmp_dir!() |> Path.join("secret_mana_test_#{:os.system_time(:millisecond)}")
    File.mkdir_p!(tmp_dir)

    on_exit(fn ->
      # Cleanup temp directory after tests
      File.rm_rf!(tmp_dir)
    end)

    # Create test config
    backend_config = %SecretMana.AgeBackend{
      version: "1.2.1",
      local_install: true,
      bin_dir: tmp_dir,
      file_type: :json,
      secret_base_path: tmp_dir,
      key_file: "age.key",
      pub_key_file: "age.pub",
      encrypted_file: "age.enc",
      string_identity_file: nil,
      binary: "age",
      key_generator_binary: "age-keygen",
      use_otp_path: false,
      absolute_bin_dir_path: tmp_dir,
      absolute_age_bin_path: Path.join(tmp_dir, "age"),
      absolute_absolute_age_keygen_bin_path: Path.join(tmp_dir, "age-keygen"),
      absolute_base_path: tmp_dir,
      absolute_key_file_path: Path.join(tmp_dir, "age.key"),
      absolute_pub_key_file_path: Path.join(tmp_dir, "age.pub"),
      absolute_encrypted_file_path: Path.join(tmp_dir, "age.enc")
    }

    config = %SecretMana.Config{
      backend: SecretMana.AgeBackend,
      otp_app: nil,
      backend_config: backend_config,
      release: false
    }

    # Create necessary files
    File.write!(config.backend_config.absolute_pub_key_file_path, "test public key")

    %{tmp_dir: tmp_dir, config: config}
  end

  describe "read/2" do
    test "reads and decodes JSON secrets", %{config: config} do
      json_content = ~s({"api_key": "secret123", "nested": {"value": "nested_secret"}})

      with_mock System, [:passthrough],
        cmd: fn cmd, args ->
          if cmd == config.backend_config.absolute_age_bin_path and "-d" in args do
            {json_content, 0}
          else
            {"", 0}
          end
        end do
        # Test without path
        result = SecretMana.read(config)
        assert result == %{"api_key" => "secret123", "nested" => %{"value" => "nested_secret"}}

        # Test with path
        assert SecretMana.read(config, ["nested", "value"]) == "nested_secret"
      end
    end

    test "reads and decodes YAML secrets", %{config: config} do
      yaml_content = """
      api_key: secret123
      nested:
        value: nested_secret
      """

      config = put_in(config.backend_config.file_type, :yaml)

      with_mock System, [:passthrough],
        cmd: fn cmd, args ->
          if cmd == config.backend_config.absolute_age_bin_path and "-d" in args do
            {yaml_content, 0}
          else
            {"", 0}
          end
        end do
        # Test without path
        result = SecretMana.read(config)
        assert result == %{"api_key" => "secret123", "nested" => %{"value" => "nested_secret"}}

        # Test with path
        assert SecretMana.read(config, ["nested", "value"]) == "nested_secret"
      end
    end

    test "raises error for invalid path format", %{config: config} do
      json_content = ~s({"api_key": "secret123"})

      with_mock System, [:passthrough],
        cmd: fn cmd, args ->
          if cmd == config.backend_config.absolute_age_bin_path and "-d" in args do
            {json_content, 0}
          else
            {"", 0}
          end
        end do
        assert_raise RuntimeError, ~r/Invalid path/, fn ->
          SecretMana.read(config, "invalid_path")
        end
      end
    end
  end

  describe "edit/1" do
    test "opens editor and re-encrypts file", %{config: config} do
      temp_file = "/tmp/temp_file"
      json_content = ~s({"test": "value"})

      with_mocks [
        {System, [:passthrough],
         cmd: fn cmd, args ->
           cond do
             cmd == "mktemp" ->
               {temp_file, 0}

             cmd == config.backend_config.absolute_age_bin_path and "-d" in args ->
               {json_content, 0}

             cmd == config.backend_config.absolute_age_bin_path and "-o" in args ->
               {"", 0}

             true ->
               {"", 0}
           end
         end},
        {System, [:passthrough], get_env: fn "EDITOR" -> "test" end},
        {File, [:passthrough], rm!: fn ^temp_file -> :ok end}
      ] do
        assert SecretMana.edit(config) == :ok
      end
    end
  end

  describe "encrypt/3" do
    test "encrypts JSON file", %{config: config} do
      json_file = "test.json"
      json_content = ~s({"test": "value"})
      File.write!(json_file, json_content)

      with_mock System, [:passthrough],
        cmd: fn cmd, args ->
          if cmd == config.backend_config.absolute_age_bin_path and "-o" in args do
            {"", 0}
          else
            {"", 0}
          end
        end do
        assert SecretMana.encrypt(config, json_file) == :ok
      end

      File.rm!(json_file)
    end

    test "encrypts YAML file", %{config: config} do
      yaml_file = "test.yaml"
      yaml_content = "test: value"
      File.write!(yaml_file, yaml_content)

      config = put_in(config.backend_config.file_type, :yaml)

      with_mock System, [:passthrough],
        cmd: fn cmd, args ->
          if cmd == config.backend_config.absolute_age_bin_path and "-o" in args do
            {"", 0}
          else
            {"", 0}
          end
        end do
        assert SecretMana.encrypt(config, yaml_file) == :ok
      end

      File.rm!(yaml_file)
    end

    test "raises error when public key is missing", %{config: config} do
      File.rm!(config.backend_config.absolute_pub_key_file_path)

      assert_raise RuntimeError, ~r/Public key not found/, fn ->
        SecretMana.encrypt(config, "test.json")
      end
    end

    test "raises error for mismatched file type", %{config: config} do
      File.write!("test.yaml", "test: value")

      assert_raise RuntimeError, ~r/Unsupported file type/, fn ->
        SecretMana.encrypt(config, "test.yaml")
      end

      File.rm!("test.yaml")
    end
  end

  describe "gen_key/1" do
    test "generates key files", %{config: config} do
      with_mocks [
        {System, [:passthrough],
         cmd: fn cmd, args ->
           cond do
             cmd == "mkdir" and "-p" in args ->
               {"", 0}

             cmd == config.backend_config.absolute_absolute_age_keygen_bin_path and "-o" in args ->
               {"", 0}

             cmd == config.backend_config.absolute_absolute_age_keygen_bin_path and "-y" in args ->
               {"public_key", 0}

             true ->
               {"", 0}
           end
         end},
        {File, [:passthrough], write!: fn _, _, _ -> :ok end}
      ] do
        assert SecretMana.gen_key(config) == :ok
      end
    end
  end

  describe "install/1" do
    test "skips installation when age is already installed", %{config: config} do
      File.mkdir_p!(config.backend_config.absolute_bin_dir_path)
      File.write!(config.backend_config.absolute_age_bin_path, "")
      File.write!(config.backend_config.absolute_absolute_age_keygen_bin_path, "")
      File.chmod!(config.backend_config.absolute_age_bin_path, 0o755)
      File.chmod!(config.backend_config.absolute_absolute_age_keygen_bin_path, 0o755)

      log =
        capture_log(fn ->
          assert SecretMana.install(config) == :ok
        end)

      assert log =~ "already installed"
    end

    test "installs age when not already installed", %{config: config} do
      log =
        capture_log(fn ->
          assert SecretMana.install(config) == :ok
        end)

      assert log =~ "Installing age..."
      assert log =~ "Installation complete"
    end
  end
end
