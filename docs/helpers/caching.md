# Caching System

CustomRC includes a centralized caching utility (`helpers/cache.sh`) that speeds up expensive tool initializations by storing generated scripts and regenerating them only when needed.

## Quick Start

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

## Features

- **Binary version checking**: Regenerate cache when tool updates
- **TTL support**: Time-based expiration (`1h`, `7d`, `30m`, `1w`, etc.)
- **Metadata tracking**: Debug information for each cache entry
- **Graceful fallback**: Keep stale cache if regeneration fails

## API Reference

### `cache_init`

Main caching function that generates and sources cached scripts.

```bash
cache_init <name> <command> [options]
```

**Parameters:**
- `name` - Unique identifier for the cache
- `command` - Shell command to generate the cache content

**Options:**
| Option | Description | Example |
|--------|-------------|---------|
| `--ttl <duration>` | Cache expiration time | `--ttl "7d"` |
| `--check-binary <path>` | Regenerate if binary is newer | `--check-binary "$(command -v fzf)"` |
| `--extension <ext>` | File extension (default: `zsh`) | `--extension "sh"` |
| `--no-source` | Don't source the file after caching | For non-shell content |

**TTL Format:**
- `s` - seconds (`30s`)
- `m` - minutes (`30m`)
- `h` - hours (`1h`)
- `d` - days (`7d`)
- `w` - weeks (`1w`)

**Examples:**

```bash
# Basic usage - cache fzf init script
cache_init "fzf" "fzf --zsh"

# With binary checking - regenerate when fzf is updated
cache_init "fzf" "fzf --zsh" --check-binary "$(command -v fzf)"

# With TTL - regenerate every 7 days
cache_init "starship" "starship init zsh" --ttl "7d"

# Combined - both binary check and TTL
cache_init "atuin" "atuin init zsh" --check-binary "$(command -v atuin)" --ttl "1d"

# Non-shell content
cache_init "my-data" "generate-data" --extension "json" --no-source
```

### `cache_get`

Read cached content into a variable (for non-sourced caches).

```bash
cache_get <name> [result_var] [--extension ext]
```

**Examples:**

```bash
# Print cache content
cache_get "my-data"

# Store in variable
cache_get "my-data" MY_VAR
echo "$MY_VAR"

# With custom extension
cache_get "config" CONFIG_DATA --extension "json"
```

### `cache_list`

Display all caches with status information.

```bash
cache_list
```

**Output:**

```
NAME            SIZE       AGE          STATUS               BINARY
----            ----       ---          ------               ------
fzf             2KB        3h ago       valid                fzf
atuin           4KB        1d ago       valid                atuin
starship        1KB        8d ago       expired (ttl: 7d)    starship
```

### `cache_clear`

Remove cached files.

```bash
# Clear specific cache
cache_clear <name>

# Clear all caches
cache_clear
```

### `cache_refresh`

Force regenerate a cache using its stored command.

```bash
cache_refresh <name>
```

## Cache Location

All caches are stored in `~/.cache/customrc/`:

```
~/.cache/customrc/
├── fzf.zsh           # Cached init script
├── atuin.zsh
├── starship.zsh
└── .meta/            # Metadata directory
    ├── fzf.meta      # Command, creation time, options
    ├── atuin.meta
    └── starship.meta
```

## Usage in Modules

Here's how to use caching in your CustomRC modules:

```bash
#!/usr/bin/env zsh
# Module: fzf.sh

command -v fzf &>/dev/null || return 0

# Use cache_init instead of eval
cache_init "fzf" "fzf --zsh" --check-binary "$(command -v fzf)"

# Your aliases and functions
alias fzfp='fzf --preview "bat --color=always {}"'
```

**Before (slow):**
```bash
eval "$(fzf --zsh)"  # ~30ms every shell start
```

**After (fast):**
```bash
cache_init "fzf" "fzf --zsh" --check-binary "$(command -v fzf)"  # ~1ms (cached)
```

## Troubleshooting

### Cache not regenerating

Check if the binary path is correct:
```bash
cache_list  # Shows binary column
```

### Force regeneration

```bash
# Method 1: Use cache_refresh
cache_refresh fzf

# Method 2: Clear and restart shell
cache_clear fzf
exec zsh
```

### View cache metadata

```bash
cat ~/.cache/customrc/.meta/fzf.meta
```

### Clear all caches

```bash
cache_clear
exec zsh
```
