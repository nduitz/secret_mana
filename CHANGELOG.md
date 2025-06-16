<!-- @format -->

# Changelog

## v0.1.0 (2025-06-16)

### Features

- Added `copy_secrets_for_release/2` to copy secrets to releases generated with `mix release`
  Can be used in mix.exs `project`'s `release` config:
  `steps: [:assemble, &SecretMana.copy_secrets_for_release(&1)]`
  `release` config is now gone.
- Added `SecretMana.generate_private_key_file/1`
  This allows users to set the private key at runtime. Use this in combination with `SecretMana.copy_secrets_for_release(release, false)`. This way secret key files are not copied to your release which would risk exposing your secrets.
- Automatic binary discovery if `local_install` is set to false and no `bin_dir` is set.
- Automatic `env` discovery for secret paths. Before you had to configure seperate dirs per config.

### Fixes

- Better editing with vim

### Misc

- Removed unused setting

## v0.0.5 (2025-03-25)

- Reworked the whole thing to a backend pattern. This allows other users to develop their own backends if needed

## v0.0.4 (2025-03-22)

- Fix pathes by using otp app path.

## v0.0.3 (2025-03-21)

- Allow enabling/disabling local_install (helpful for deployments and CIs)

## v0.0.2 (2025-03-21)

### Fixes

- Fix file type checking by skipping after editing.

## v0.0.1 (2025-03-21)

### Features

- Initial release of SecretMana
- Automatic installation of age binaries for different operating systems
- Support for managing encrypted secrets in JSON and YAML formats
- Read encrypted secrets with support for nested keys
- Edit secrets with your preferred editor (uses $EDITOR or falls back to vim)
- Encrypt files using age with public key encryption
- Generate new age key pairs
- Configuration system with sensible defaults and customization options

### Implementation Details

- Automatic detection of system architecture for binary downloads
- Support for Darwin (macOS), Linux, and Windows platforms
- Secure SSL connections for downloading binaries
- Fallback mechanisms for different network configurations
