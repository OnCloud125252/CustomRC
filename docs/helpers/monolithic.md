# Monolithic Helper

The `monolithic.sh` helper generates and manages a cached monolithic RC file for fast production startup without debug instrumentation.

## Location

```
helpers/monolithic.sh
```

## Overview

This helper creates a single combined shell script from all your modules, stripping out timing instrumentation for maximum performance. It's designed for production use where you want the fastest possible shell startup.

## How It Works

```
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│  Global/*.sh    │     │  Darwin/*.sh    │     │  Linux/*.sh     │
└────────┬────────┘     └────────┬────────┘     └────────┬────────┘
         │                       │                       │
         └───────────────────────┼───────────────────────┘
                                 ▼
                    ┌────────────────────────┐
                    │  generate_monolithic   │
                    │  - Respects ignore     │
                    │  - No timing overhead  │
                    │  - Adds file markers   │
                    └───────────┬────────────┘
                                ▼
                    ┌────────────────────────┐
                    │  ~/.cache/customrc/    │
                    │  monolithic.sh         │
                    └────────────────────────┘
```

## Global Variables

| Variable | Description |
|----------|-------------|
| `CUSTOMRC_MONOLITHIC_CACHE` | Path to cached file (default: `~/.cache/customrc/monolithic.sh`) |

## Functions

### `_monolithic_needs_rebuild`

Checks if any source file is newer than the cached monolithic file.

```bash
_monolithic_needs_rebuild <cache_file>
```

**Returns:**
- `0` if rebuild is needed (cache missing or source files changed)
- `1` if cache is still valid

**Checks:**
- Cache file exists
- `configs.sh` modification time
- All files in `Global/`, `Darwin/`, and `Linux/` directories

### `_append_modules_from_dir`

Appends modules from a directory to the monolithic file, respecting ignore lists.

```bash
_append_modules_from_dir <directory> <category> <cache_file> [ignored_files...]
```

**Parameters:**
- `directory` - Path to module directory
- `category` - Category label (for file markers)
- `cache_file` - Path to the output cache file
- `ignored_files` - Files to skip

### `generate_monolithic_file`

Generates a clean monolithic file without timing instrumentation.

```bash
generate_monolithic_file <cache_file>
```

**Parameters:**
- `cache_file` - Path where the combined script will be written

**Behavior:**
1. Creates cache directory if needed
2. Writes header with generation timestamp
3. Appends Global modules (respecting `CUSTOMRC_GLOBAL_IGNORE_LIST`)
4. Detects OS and appends platform-specific modules
5. Respects `CUSTOMRC_DARWIN_IGNORE_LIST` or `CUSTOMRC_LINUX_IGNORE_LIST`

## Generated File Structure

```bash
# Monolithic RC - Generated 2024-01-15 10:30:45
# Do not edit - regenerated automatically when source files change

# === aliases.sh [Global] ===
alias ll='ls -la'
# ...

# === functions.sh [Global] ===
myfunction() { ... }
# ...

# === brew.sh [Darwin] ===
eval "$(/opt/homebrew/bin/brew shellenv)"
# ...
```

## Cache Invalidation

The monolithic cache is automatically invalidated when:

- Any module file in `rc-modules/` is modified
- `configs.sh` is modified
- The cache file doesn't exist

This is checked via file modification timestamps using `stat`.

## Usage

The monolithic helper is typically used by `customrc.sh` in production mode:

```bash
if [[ "$CUSTOMRC_DEBUG_MODE" != true ]]; then
  if _monolithic_needs_rebuild "$CUSTOMRC_MONOLITHIC_CACHE"; then
    generate_monolithic_file "$CUSTOMRC_MONOLITHIC_CACHE"
  fi
  source "$CUSTOMRC_MONOLITHIC_CACHE"
fi
```

## Performance Comparison

| Mode | Typical Startup | Use Case |
|------|-----------------|----------|
| Debug mode | 150-300ms | Development, troubleshooting |
| Monolithic | 20-50ms | Daily use, production |

The monolithic approach is faster because:
- Single file read operation
- No timing instrumentation overhead
- No per-file debug checks

## Manual Regeneration

To force regeneration:

```bash
# Remove the cache
rm ~/.cache/customrc/monolithic.sh

# Restart shell
exec zsh
```

## See Also

- [loader.md](./loader.md) - Debug mode with timing instrumentation
- [caching.md](./caching.md) - General caching system
- [../optimized-modules.md](../optimized-modules.md) - Module optimization guide
