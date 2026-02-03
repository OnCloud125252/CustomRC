# CustomRC

**Breakdown massive rc files like bashrc or zshrc into manageable modules and easily control which modules to be loaded on startup.**

- [Overview](#overview)
- [Features](#features)
  - [Caching System](#caching-system)
  - [Benchmarking](#benchmarking)
- [Project Structure](#project-structure)
- [FAQs](#faqs)
- [Installation](#installation)

## Overview

RC stands for "run command". It is a file that contains commands to be executed. Usually, it contains the commands to be executed when the shell is started.

This project allows you to split your monolithic shell configuration into smaller, organized files based on functionality or operating system.

Reference: [Wiki/RUNCOM](https://en.wikipedia.org/wiki/RUNCOM)

## Features

- **Modular Configuration**: Break down large `.zshrc` or `.bashrc` files into smaller, maintainable modules.
- **Platform Specific Loading**: Automatically load modules based on your OS (Global, Darwin, Linux).
- **Startup Control**: Easily manage which modules are loaded when your shell starts.
- **Performance Optimized**: Modules use lazy loading, caching, and conditional loading for fast shell startup. See [Writing Optimized Modules](docs/optimized-modules.md).

### Caching System

CustomRC includes a centralized caching utility (`helpers/cache.sh`) to speed up expensive tool initializations:

```bash
# Cache a tool's init script with automatic binary version checking
cache_init "fzf" "fzf --zsh" --check-binary "$(command -v fzf)"

# Cache with TTL expiration
cache_init "myconfig" "generate-config" --ttl "7d"

# Management commands
cache_list      # View all caches with status
cache_clear     # Clear all caches
cache_refresh   # Force regenerate a specific cache
```

**Features:**
- Binary version checking (regenerate when tool updates)
- TTL support (`1h`, `7d`, `30m`, etc.)
- Metadata tracking for debugging
- Graceful fallback to stale cache on regeneration failure

### Benchmarking

Use `benchmark.sh` to measure your shell startup time and compare against a monolithic build:

```bash
./benchmark.sh
```

This generates a monolithic version of your config and compares load times.

## Project Structure

```
~/.customrc/
├── customrc.sh          # Main entry point
├── configs.sh           # Configuration and ignore lists
├── benchmark.sh         # Performance testing tool
├── helpers/
│   ├── cache.sh         # Caching utility
│   ├── logging.sh       # Output formatting
│   ├── timing.sh        # Execution timing
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
Notice that the rc file in this repository is for personal use. Some modules/tools may not work in your environment or may conflict with your existing setup. You should take a look at the modules in `~/.customrc/rc-modules/Global`, `~/.customrc/rc-modules/Darwin` and `~/.customrc/rc-modules/Linux` before using it to ensure compatibility.

#### How do I ignore slow modules?
Add module filenames to the ignore list in `configs.sh`:

```bash
CUSTOMRC_GLOBAL_IGNORE_LIST=(
  "nvm.sh"       # 200ms+ - use fnm instead
  "thefuck.sh"   # 100ms+ - lazy load if needed
)
```

#### How do I clear the cache?
Run `cache_clear` to remove all caches, or `cache_clear <name>` for a specific one. Caches are stored in `~/.cache/customrc/`.

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
