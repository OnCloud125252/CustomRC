# CustomRC

*Break down massive rc files like bashrc or zshrc into manageable modules with automatic caching for fast shell startup.*

- [CustomRC](#customrc)
  - [Overview](#overview)
  - [Features](#features)
    - [Debug Mode](#debug-mode)
    - [Production Mode](#production-mode)
    - [Caching System](#caching-system)
  - [Project Structure](#project-structure)
  - [FAQs](#faqs)
      - [Is this safe to use on my machine?](#is-this-safe-to-use-on-my-machine)
      - [How do I ignore slow modules?](#how-do-i-ignore-slow-modules)
      - [How do I clear the cache?](#how-do-i-clear-the-cache)
      - [How do I force regenerate the monolithic cache?](#how-do-i-force-regenerate-the-monolithic-cache)
      - [How do I add a new module?](#how-do-i-add-a-new-module)
  - [Installation](#installation)

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

See [Writing Optimized Modules](docs/optimized-modules.md) for performance best practices.

### Debug Mode

Enable verbose output with per-module timing by setting `CUSTOMRC_DEBUG_MODE=true` in `configs.sh`:

```
[i] Initializing Customrc...
━━━━[customrc]━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✓ Loaded: fzf.sh [Global] (3ms)
✓ Loaded: bat.sh [Global] (1ms)
✗ Ignored: nvm.sh [Global]
✓ Loaded: brew.sh [Darwin] (2ms)
━━━━[customrc]━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[i] Initialization complete
    ✓ Loaded: 24
    ✗ Ignored: 5
    ⚠ Duration: 89ms
```

### Production Mode

When `CUSTOMRC_DEBUG_MODE=false`, CustomRC generates a monolithic cache file combining all modules. This cache:

- Auto-regenerates when any module or `configs.sh` changes
- Sources instantly without per-file overhead
- Lives at `~/.cache/customrc/monolithic.sh`

### Caching System

The centralized caching utility (`helpers/cache.sh`) speeds up expensive tool initializations with binary version checking, TTL support, and automatic regeneration.

See [Caching System](docs/caching.md) for full API documentation and usage examples.

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
    └── optimized-modules.md  # Performance optimization guide
```

## FAQs

#### Is this safe to use on my machine?
This repository contains personal configurations. Some modules may not work in your environment or may conflict with your existing setup. Review the modules in `rc-modules/Global`, `rc-modules/Darwin`, and `rc-modules/Linux` before using.

#### How do I ignore slow modules?
Add module filenames to the ignore lists in `configs.sh`:

```bash
CUSTOMRC_GLOBAL_IGNORE_LIST=(
  "nvm.sh"       # 200ms+ - use fnm instead
  "thefuck.sh"   # 100ms+ - lazy load if needed
)

CUSTOMRC_DARWIN_IGNORE_LIST=(
  "iterm.sh"     # Not needed if using other terminal
)

CUSTOMRC_LINUX_IGNORE_LIST=()
```

#### How do I clear the cache?
Run `cache_clear` to remove all caches, or `cache_clear <name>` for a specific one. Caches are stored in `~/.cache/customrc/`.

#### How do I force regenerate the monolithic cache?
Delete the cache file and restart your shell:

```bash
rm ~/.cache/customrc/monolithic.sh
exec zsh
```

#### How do I add a new module?
Create a `.sh` file in the appropriate directory:
- `rc-modules/Global/` for cross-platform modules
- `rc-modules/Darwin/` for macOS-specific modules
- `rc-modules/Linux/` for Linux-specific modules

The module will be automatically loaded on next shell start.

## Installation

Clone the repository:

```bash
git clone --recurse-submodules https://github.com/OnCloud125252/CustomRC.git ~/.customrc
```

Add the configuration to your shell profile (e.g., `~/.zshrc`):

```bash
cat << 'EOF' >> ~/.zshrc
# CustomRC
export CUSTOMRC_PATH="$HOME/.customrc"
source $CUSTOMRC_PATH/customrc.sh
# CustomRC End
EOF
```
