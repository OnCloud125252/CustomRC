# Logging Helper

The `logging.sh` helper provides debug-aware logging functions for CustomRC, outputting formatted messages only when debug mode is enabled.

## Location

```
helpers/logging.sh
```

## Overview

This helper provides functions for displaying formatted output during shell initialization. All output is conditional on `CUSTOMRC_DEBUG_MODE` being set to `true`, keeping normal shell startup clean and silent.

## Functions

### `print_divider`

Prints a full-width divider line with a centered label.

```bash
print_divider [color] [label]
```

**Parameters:**
- `color` - ANSI color code (default: `$PURPLE`)
- `label` - Text to display in the divider (default: `customrc`)

**Example Output:**
```
━━━━[customrc]━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

**Usage:**
```bash
print_divider "$BLUE" "Global Modules"
print_divider "$CYAN" "Darwin"
print_divider  # Uses defaults
```

### `log_message`

Logs a message only when debug mode is enabled.

```bash
log_message <message>
```

**Parameters:**
- `message` - The message to display (supports ANSI escape codes)

**Usage:**
```bash
log_message "${CHECK} Loaded: mymodule.sh"
log_message "${WARN} Skipping optional module"
```

## Debug Mode

Both functions check `CUSTOMRC_DEBUG_MODE` before outputting. To enable debug output:

```bash
# In your shell or configs.sh
export CUSTOMRC_DEBUG_MODE=true
```

When debug mode is disabled (the default), these functions return immediately without any output, ensuring fast shell startup.

## Terminal Width

`print_divider` uses `CUSTOMRC_TERMINAL_WIDTH` to determine the divider length:

```bash
# Set custom width (default: 80)
export CUSTOMRC_TERMINAL_WIDTH=120
```

## Usage in Modules

```bash
#!/usr/bin/env zsh
# Module: example.sh

# This only shows when debug mode is on
log_message "${INFO} Initializing example module..."

# Module logic here
export EXAMPLE_VAR="value"

log_message "${CHECK} Example module loaded"
```

## See Also

- [styles.md](./styles.md) - Color and symbol definitions
- [timing.md](./timing.md) - Performance measurement
