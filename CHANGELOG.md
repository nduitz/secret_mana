<!-- @format -->

# Changelog

## v0.1.0 (2024-03-21)

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
