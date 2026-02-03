# Cache Helper

The `cache.sh` helper provides a centralized caching system for CustomRC, enabling fast shell initialization by caching expensive command outputs with TTL support and binary version checking.

## Location

```
helpers/cache.sh
```

## Overview

This helper reduces shell startup time by caching the output of slow initialization commands (like `eval "$(tool init zsh)"`). Caches are automatically invalidated based on TTL expiration or when the source binary is updated.

## Configuration

```bash
# Custom cache directory (default: ~/.cache/customrc)
export CUSTOMRC_CACHE_DIR="$HOME/.cache/customrc"
```

## Functions

### `cache_init`

Main caching function that initializes or regenerates a cache.

```bash
cache_init <name> <command> [options]
```

**Parameters:**
- `name` - Unique identifier for the cache
- `command` - Shell command to generate cache content

**Options:**
| Option | Description |
|--------|-------------|
| `--ttl <duration>` | Cache lifetime (e.g., `1h`, `7d`, `3600`) |
| `--check-binary <path>` | Regenerate if binary is newer than cache |
| `--extension <ext>` | File extension (default: `zsh`) |
| `--no-source` | Don't source the cache file after creation |

**TTL Format:**
| Unit | Example | Meaning |
|------|---------|---------|
| `s` | `30s` | 30 seconds |
| `m` | `15m` | 15 minutes |
| `h` | `2h` | 2 hours |
| `d` | `7d` | 7 days |
| `w` | `1w` | 1 week |

**Usage:**
```bash
# Cache with TTL
cache_init "starship" "starship init zsh" --ttl "7d"

# Cache with binary version checking
cache_init "zoxide" "zoxide init zsh" --check-binary "$(command -v zoxide)"

# Combined: TTL + binary check
cache_init "fzf" "fzf --zsh" \
  --ttl "7d" \
  --check-binary "$(command -v fzf)"

# Non-shell content (won't be sourced)
cache_init "version" "myapp --version" --no-source --extension "txt"
```

**Returns:** `0` on success, `1` on failure

### `cache_get`

Reads cached content into a variable (for non-sourced caches).

```bash
cache_get <name> [result_var] [--extension ext]
```

**Parameters:**
- `name` - Cache identifier
- `result_var` - Variable to store content (optional, prints if omitted)

**Usage:**
```bash
# Print cache content
cache_get "version"

# Store in variable
local my_version
cache_get "version" my_version --extension "txt"
```

**Returns:** `0` if cache exists and has content, `1` otherwise

### `cache_list`

Displays all caches with status information.

```bash
cache_list
```

**Example Output:**
```
NAME            SIZE       AGE          STATUS               BINARY
----            ----       ---          ------               ------
starship        12KB       2d ago       valid                starship
zoxide          1KB        5h ago       valid                zoxide
fzf             3KB        8d ago       expired (ttl: 7d)    fzf
mise            2KB        1d ago       stale (binary updated) mise
```

### `cache_clear`

Removes specific or all caches.

```bash
cache_clear [name]
```

**Usage:**
```bash
# Clear specific cache
cache_clear "starship"

# Clear all caches
cache_clear
```

### `cache_refresh`

Forces regeneration of a specific cache using stored metadata.

```bash
cache_refresh <name>
```

**Usage:**
```bash
cache_refresh "starship"
```

This function reads the original command and options from metadata and re-executes the cache generation.

## Cache Invalidation

Caches are automatically invalidated when:

1. **TTL Expired** - The cache file age exceeds the specified TTL
2. **Binary Updated** - The source binary is newer than the cache file
3. **Cache Missing** - The cache file doesn't exist

When regeneration fails, stale cache is preserved to prevent shell breakage.

## File Structure

```
~/.cache/customrc/
├── starship.zsh          # Cached shell init script
├── zoxide.zsh
├── fzf.zsh
└── .meta/
    ├── starship.meta     # Metadata (command, created, binary, ttl)
    ├── zoxide.meta
    └── fzf.meta
```

## Performance Impact

Using caching can dramatically improve shell startup time:

| Tool | Without Cache | With Cache |
|------|---------------|------------|
| `starship init zsh` | ~50ms | ~2ms |
| `zoxide init zsh` | ~15ms | ~1ms |
| `fzf --zsh` | ~10ms | ~1ms |

## Usage in Modules

```bash
#!/usr/bin/env zsh
# Module: tools.sh

# Cache expensive tool initializations
if command -v starship &>/dev/null; then
  cache_init "starship" "starship init zsh" \
    --ttl "7d" \
    --check-binary "$(command -v starship)"
fi

if command -v zoxide &>/dev/null; then
  cache_init "zoxide" "zoxide init zsh" \
    --check-binary "$(command -v zoxide)"
fi
```

## Internal Functions

These functions are used internally by `cache_init`:

| Function | Purpose |
|----------|---------|
| `_cache_ttl_to_seconds` | Converts TTL string to seconds |
| `_cache_is_expired` | Checks if cache has exceeded TTL |
| `_cache_binary_newer` | Checks if binary is newer than cache |
| `_cache_write_meta` | Writes metadata for a cache entry |
| `_cache_read_meta` | Reads metadata value for a cache entry |

## See Also

- [timing.md](./timing.md) - Performance measurement
- [../optimized-modules.md](../optimized-modules.md) - Optimization patterns
- [logging.md](./logging.md) - Debug output functions
