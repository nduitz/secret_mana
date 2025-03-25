<!-- @format -->

# Changelog

### v0.0.5 (2024-03-25)

- Reworked the whole thing to a backend pattern. This allows other users to develop their own backends if needed

### v0.0.4 (2024-03-22)

- Fix pathes by using otp app path.

### v0.0.3 (2024-03-21)

- Allow enabling/disabling local_install (helpful for deployments and CIs)

## v0.0.2 (2024-03-21)

### Fixes

- Fix file type checking by skipping after editing.

## v0.0.1 (2024-03-21)

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
