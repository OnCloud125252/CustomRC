# CustomRC

*Break down massive rc files like bashrc or zshrc into manageable modules with automatic caching for fast shell startup.*

## Overview

RC stands for "run command"—a file containing commands executed when the shell starts. This project splits your monolithic shell configuration into smaller, organized files based on functionality or operating system.

You get the maintainability of modular configs with the performance of a single cached file.

Reference: [Wiki/RUNCOM](https://en.wikipedia.org/wiki/RUNCOM)

## Features

- **Modular Configuration**: Break down large `.zshrc` or `.bashrc` files into smaller, maintainable modules.
- **Platform Specific Loading**: Automatically load modules based on your OS (Global, Darwin, Linux).
- **Dual Mode Operation**: Debug mode for development with timing, production mode for instant startup.
- **Smart Caching**: Monolithic cache auto-regenerates when source files change.
- **Ignore Lists**: Easily disable slow or unused modules per platform.

## Quick Start

```bash
# Clone the repository
git clone --recurse-submodules https://github.com/OnCloud125252/CustomRC.git ~/.customrc

# Add to your shell profile
echo 'export CUSTOMRC_PATH="$HOME/.customrc"' >> ~/.zshrc
echo 'source $CUSTOMRC_PATH/customrc.sh' >> ~/.zshrc

# Restart shell
exec zsh
```

See the [User Guide](docs/user-guide.md) for detailed installation and configuration instructions.

## Documentation

| Document | Description |
|----------|-------------|
| [User Guide](docs/user-guide.md) | Installation and FAQs |
| [Configuration](docs/configuration.md) | Operating modes, ignore lists, cache management |
| [Writing Optimized Modules](docs/optimized-modules.md) | Performance best practices |
| [Caching System](docs/caching.md) | Cache helper API documentation |


## Project Structure

```
~/.customrc/
├── customrc.sh          # Main entry point
├── configs.sh           # Configuration and ignore lists
├── helpers/
│   ├── cache.sh         # Caching utility with TTL and binary checking
│   ├── monolithic.sh    # Production mode cache generator
│   ├── loader.sh        # Debug mode module loader with timing
│   ├── logging.sh       # Output formatting
│   ├── timing.sh        # Execution timing utilities
│   └── styles.sh        # Color and style definitions
├── rc-modules/
│   ├── Global/          # Cross-platform modules
│   ├── Darwin/          # macOS-specific modules
│   └── Linux/           # Linux-specific modules
└── docs/
    ├── user-guide.md         # Installation and usage guide
    ├── optimized-modules.md  # Performance optimization guide
    └── caching.md            # Caching system documentation
```
