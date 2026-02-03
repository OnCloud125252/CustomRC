# CustomRC

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Shell: Bash 4+](https://img.shields.io/badge/Shell-Bash%204%2B-green.svg)](https://www.gnu.org/software/bash/)
[![Shell: Zsh 5+](https://img.shields.io/badge/Shell-Zsh%205%2B-green.svg)](https://www.zsh.org/)

*Break down massive rc files like bashrc or zshrc into manageable modules with automatic caching for fast shell startup.*

## Overview

RC stands for "run command"—a file containing commands executed when the shell starts. CustomRC splits your monolithic shell configuration into smaller, organized files based on functionality or operating system.

You get the maintainability of modular configs with the performance of a single cached file.

## Features

- **Modular Configuration** — Organize your shell config into logical modules
- **Platform-Specific Loading** — Automatically load modules for your OS (Global, Darwin, Linux)
- **Dual Mode Operation** — Debug mode for development with timing, production mode for instant startup
- **Smart Caching** — Monolithic cache auto-regenerates when source files change
- **Ignore Lists** — Easily disable slow or unused modules per platform
- **Your Configs, Your Repo** — Keep your personal modules in a separate repository

## Quick Start

### Installation

```bash
# Clone the repository
git clone https://github.com/OnCloud125252/CustomRC.git ~/.customrc

# Run the installer
~/.customrc/install.sh
```

The installer will:
1. Create `rc-modules/` from the example templates
2. Back up your existing shell config
3. Add CustomRC to your shell startup

### Manual Installation

```bash
# Clone the repository
git clone https://github.com/OnCloud125252/CustomRC.git ~/.customrc

# Copy template modules
cp -r ~/.customrc/rc-modules.example ~/.customrc/rc-modules

# Add to your shell profile (~/.zshrc or ~/.bashrc)
export CUSTOMRC_PATH="$HOME/.customrc"
source "$CUSTOMRC_PATH/customrc.sh"

# Restart your shell
exec $SHELL
```

## Usage

### Adding Your Own Modules

Edit the files in `rc-modules/` to add your aliases, functions, and exports:

```
rc-modules/
├── Global/          # Loaded on all platforms
│   └── ...
├── Darwin/          # Loaded only on macOS
│   └── ...
└── Linux/           # Loaded only on Linux
    └── ...
```

### Debug Mode

Enable debug mode to see timing information for each module:

```bash
export CUSTOMRC_DEBUG_MODE=true
source ~/.customrc/customrc.sh
```

### Syncing Across Machines

Your `rc-modules/` directory is gitignored, so you can:

1. Create a separate repository for your personal modules
2. Clone it as `rc-modules/` in your CustomRC directory
3. Keep your personal configs synced without forking CustomRC

See the [User Guide: Syncing Across Machines](docs/user-guide.md#syncing-across-machines) for detailed instructions.

## Documentation

| Document | Description |
|----------|-------------|
| [User Guide](docs/user-guide.md) | Installation, customization, and syncing |
| [Configuration](docs/configuration.md) | Operating modes, ignore lists, cache management |
| [Writing Optimized Modules](docs/optimized-modules.md) | Performance best practices |
| [Caching System](docs/caching.md) | Cache helper API documentation |

## Contributing

Contributions are welcome! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Reference

- [Wikipedia: RUNCOM](https://en.wikipedia.org/wiki/RUNCOM)
