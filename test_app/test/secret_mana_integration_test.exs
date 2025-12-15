defmodule TestApp.SecretManaIntegrationTest do
  use ExUnit.Case, async: false

  require SecretMana
  import ExUnit.CaptureIO

  @test_secret %{
    "database" => %{
      "host" => "localhost",
      "password" => "secret123"
    },
    "api_key" => "test-api-key"
  }

  @test_tmp_dir "tmp/"

  setup_all do
    Mix.Task.run("secret_mana.install")

    # Clean up any existing secrets
    cleanup_secrets()

    # Generate secrets for each environment
    for env <- [:dev, :test, :prod] do
      setup_secrets_for_env(env)
    end

    on_exit(&cleanup_secrets/0)
    :ok
  end

  describe "SecretMana with secrets directories" do
    test "automatically detects development mode and reads from secrets/test" do
      import SecretMana
      # Ensure we're in test environment
      assert Mix.env() == :test

      # SecretMana should automatically read from secrets/test/
      result = read!()

      assert result == @test_secret
      assert read!(["database", "password"]) == "secret123"
    end

    test "can generate and encrypt secrets in development mode" do
      File.mkdir_p!(@test_tmp_dir)
      tmp_file = Path.join(@test_tmp_dir, "test.json")

      # Write a test file
      File.write!(tmp_file, Jason.encode!(@test_secret))

      # Should be able to encrypt it
      config = SecretMana.Config.new()
      assert :ok = SecretMana.encrypt(config, tmp_file)

      # Clean up
      File.rm!(tmp_file)
    end

    test "copy_secrets_for_release/1 copies secrets to release config/secrets structure" do
      # Create a mock release struct
      release = %{
        name: :test_app,
        version: "0.1.0",
        path: "/tmp/test_release",
        options: [env: :prod]
      }

      # Ensure the release directory exists and is clean
      File.rm_rf!(release.path)
      File.mkdir_p!(release.path)

      output =
        capture_io(fn ->
          result = SecretMana.copy_secrets_for_release(release)
          assert result == release
        end)

      # Check that secrets were copied to config/secrets (no environment subdirectory)
      expected_dest =
        Path.join([
          release.path,
          "lib",
          "test_app-0.1.0",
          "config",
          "secrets"
        ])

      assert File.exists?(expected_dest)
      assert File.exists?(Path.join(expected_dest, "age.pub"))
      assert File.exists?(Path.join(expected_dest, "age.enc"))

      assert output =~ "SecretMana: Copied prod secrets to release"

      # Clean up
      File.rm_rf!(release.path)
    end

    test "handles missing secrets gracefully during release copying" do
      # Create a mock release struct for non-existent environment
      release = %{
        name: :test_app,
        version: "0.1.0",
        path: "/tmp/test_release_missing",
        options: [env: :staging]
      }

      File.rm_rf!(release.path)
      File.mkdir_p!(release.path)

      output =
        capture_io(fn ->
          result = SecretMana.copy_secrets_for_release(release)
          assert result == release
        end)

      assert output =~ "No secrets found"

      # Clean up
      File.rm_rf!(release.path)
    end
  end

  # Helper functions
  defp setup_secrets_for_env(env) do
    # Use the SecretMana API directly instead of Mix tasks
    %{backend_config: %{secret_base_path: secret_base_path}} =
      config = SecretMana.Config.new(env)

    # Install age binary
    SecretMana.install(config)

    # Generate key pair
    SecretMana.gen_key(config)

    # Create and encrypt test secrets file
    secrets_file = Path.join(secret_base_path, "test_secrets.json")
    File.write!(secrets_file, Jason.encode!(@test_secret))

    # Encrypt the secrets file
    SecretMana.encrypt(config, secrets_file)

    # Clean up temporary file
    File.rm!(secrets_file)
  end

  defp cleanup_secrets do
    %{backend_config: %{secret_base_path: secret_base_path}} =
      SecretMana.Config.new()

    File.rm_rf!(secret_base_path)
  end
end
