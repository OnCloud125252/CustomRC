# Loader Helper

The `loader.sh` helper provides functions for loading RC modules with timing instrumentation and ignore list support.

## Location

```
helpers/loader.sh
```

## Overview

This helper handles the core module loading logic for CustomRC. It processes directories of shell scripts, applies ignore lists, adds timing instrumentation, and combines everything into a single temporary file for fast sourcing.

## Functions

### `is_ignored`

Checks if a filename is in the provided ignore list.

```bash
is_ignored <filename> [ignored_items...]
```

**Parameters:**
- `filename` - The file name to check
- `ignored_items` - List of filenames to ignore

**Returns:**
- `0` if the file is in the ignore list
- `1` if the file is not ignored

**Usage:**
```bash
if is_ignored "slow-module.sh" "${CUSTOMRC_GLOBAL_IGNORE_LIST[@]}"; then
  echo "Skipping slow-module.sh"
fi
```

### `add_file_to_combined`

Appends a file's content to the combined script with timing instrumentation.

```bash
add_file_to_combined <filepath> <filename> <category>
```

**Parameters:**
- `filepath` - Full path to the file
- `filename` - Name of the file (for logging)
- `category` - Category label (e.g., "Global", "Darwin")

**Behavior:**
- Wraps file content with start/end markers
- Adds timing code to measure load duration
- Outputs debug information when `CUSTOMRC_DEBUG_MODE` is enabled
- Increments `CUSTOMRC_LOADED_COUNT`

**Generated Structure:**
```bash
# === Start of mymodule.sh [Global] ===
_file_start_time=$(date +%s%N)
# ... file content ...
_file_end_time=$(date +%s%N)
_file_duration=$(( (_file_end_time - _file_start_time) / 1000000 ))
if [[ "$CUSTOMRC_DEBUG_MODE" == true ]]; then
  # Color-coded duration output
fi
# === End of mymodule.sh [Global] ===
```

### `process_rc_directory`

Processes all RC files in a directory, respecting the ignore list.

```bash
process_rc_directory <directory> <category> [ignored_files...]
```

**Parameters:**
- `directory` - Path to the directory containing RC files
- `category` - Category label for logging
- `ignored_files` - Files to skip (optional)

**Behavior:**
- Iterates through all files in the directory
- Skips files in the ignore list (increments `CUSTOMRC_IGNORED_COUNT`)
- Calls `add_file_to_combined` for non-ignored files
- Logs ignored files when debug mode is enabled

**Usage:**
```bash
process_rc_directory \
  "$CUSTOMRC_RC_MODULES_PATH/Global" \
  "Global" \
  "${CUSTOMRC_GLOBAL_IGNORE_LIST[@]}"
```

## Global Variables

The loader uses these global variables:

| Variable | Description |
|----------|-------------|
| `TEMP_COMBINED_RC` | Path to the temporary combined script |
| `CUSTOMRC_LOADED_COUNT` | Counter for loaded modules |
| `CUSTOMRC_IGNORED_COUNT` | Counter for ignored modules |
| `CUSTOMRC_DEBUG_MODE` | Enables debug output when `true` |

## How It Works

1. **Directory Processing**: `process_rc_directory` iterates through module files
2. **Ignore Filtering**: `is_ignored` checks each file against the ignore list
3. **Instrumentation**: `add_file_to_combined` wraps content with timing code
4. **Combination**: All modules are appended to `TEMP_COMBINED_RC`
5. **Single Source**: The combined file is sourced once for performance

## Debug Output

When `CUSTOMRC_DEBUG_MODE=true`, you'll see:

```
[✓] Loaded: aliases.sh [Global] (2ms)
[✓] Loaded: functions.sh [Global] (5ms)
[✗] Ignored: slow-module.sh [Global]
```

## See Also

- [monolithic.md](./monolithic.md) - Production mode without instrumentation
- [timing.md](./timing.md) - Duration calculation and coloring
- [../optimized-modules.md](../optimized-modules.md) - Module optimization guide
