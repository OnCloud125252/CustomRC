# CLI Output Style

The CustomRC CLI uses a consistent output style for all commands, providing clear visual feedback through colors, symbols, and dividers.

## Location

```
helpers/customrc-cli.sh (Styles & Logging section)
```

## Overview

The CLI defines its own prefixed color and symbol variables (`_CLI_*`) to avoid collision with debug mode variables that are unset after initialization. This ensures the CLI remains functional regardless of debug mode state.

## Colors

| Variable | Color | ANSI Code | Usage |
|----------|-------|-----------|-------|
| `$_CLI_RED` | Red | `\033[0;31m` | Errors, failures |
| `$_CLI_GREEN` | Green | `\033[0;32m` | Success, enabled states |
| `$_CLI_YELLOW` | Yellow | `\033[0;33m` | Warnings |
| `$_CLI_BLUE` | Blue | `\033[0;34m` | Paths, values |
| `$_CLI_PURPLE` | Purple | `\033[0;35m` | Headers, dividers |
| `$_CLI_CYAN` | Cyan | `\033[0;36m` | Categories, info |
| `$_CLI_WHITE` | White | `\033[0;37m` | Labels |
| `$_CLI_NC` | No Color | `\033[0m` | Reset |

## Symbols

| Variable | Symbol | Color | Usage |
|----------|--------|-------|-------|
| `$_CLI_CHECK` | `[✓]` | Green | Success messages |
| `$_CLI_CROSS` | `[✗]` | Red | Error messages |
| `$_CLI_WARN` | `[!]` | Yellow | Warning messages |
| `$_CLI_INFO` | `[i]` | Cyan | Informational messages |

## Output Functions

### `_customrc_info`

Prints an informational message with cyan `[i]` prefix.

```bash
_customrc_info "Fetching from origin/main..."
```

**Output:**
```
[i] Fetching from origin/main...
```

### `_customrc_success`

Prints a success message with green `[✓]` prefix.

```bash
_customrc_success "Module created successfully"
```

**Output:**
```
[✓] Module created successfully
```

### `_customrc_warn`

Prints a warning message with yellow `[!]` prefix.

```bash
_customrc_warn "You have 3 uncommitted changes"
```

**Output:**
```
[!] You have 3 uncommitted changes
```

### `_customrc_error`

Prints an error message with red `[✗]` prefix.

```bash
_customrc_error "Failed to connect to remote"
```

**Output:**
```
[✗] Failed to connect to remote
```

### `_customrc_divider`

Prints a full-width divider line with a centered label.

```bash
_customrc_divider [color] [label]
```

**Parameters:**
- `color` - ANSI color code (default: `$_CLI_PURPLE`)
- `label` - Text to display in brackets (default: `customrc`)

**Example:**
```bash
_customrc_divider "$_CLI_PURPLE" "CustomRC Status"
```

**Output:**
```
━━━━[CustomRC Status]━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

## Output Patterns

### Command Headers

Commands that display status information use dividers to frame the output:

```
━━━━[CustomRC Status]━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  Version:     1.0.0
  Path:        /Users/you/.customrc
  Modules:     Global: 12, Darwin: 5, Linux: 0

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### Health Checks

The `doctor` command uses symbols to indicate pass/fail status:

```
[✓] CustomRC directory exists: /Users/you/.customrc
[✓] rc-modules directory exists
[✓] Helper found: cache.sh
[✓] Helper found: monolithic.sh

[i] Checking module syntax...
[✓] All modules have valid syntax

[✓] All checks passed!
```

### Module Lists

Modules are listed with status indicators and category grouping:

```
Modules:

  Global/
    ✓ aliases.sh
    ✓ functions.sh
    ✗ nvm.sh (ignored)

  Darwin/
    ✓ brew.sh
    ✗ iterm.sh (ignored)
```

### Progress Operations

Multi-step operations show progress with info messages:

```
[i] Fetching from origin/main...
[i] Found 3 new commit(s)

a1b2c3d feat: add new feature
d4e5f6g fix: resolve bug
h7i8j9k docs: update readme

[i] Pulling updates...
[✓] Updated CustomRC to latest version

[i] Rebuilding cache...
[✓] Rebuilt monolithic cache

[✓] Update complete!
[i] Restart your shell to apply changes
```

## Design Principles

### 1. Consistent Prefixes

All messages start with a bracketed symbol for quick visual scanning:
- `[i]` - Action in progress or neutral info
- `[✓]` - Action completed successfully
- `[!]` - Non-fatal issue or advisory
- `[✗]` - Fatal error or failure

### 2. Color Semantics

Colors have consistent meaning across all commands:
- **Green** - Success, enabled, loaded
- **Red** - Error, disabled, ignored
- **Yellow** - Warning, caution
- **Cyan** - Categories, informational
- **Purple** - Headers, dividers
- **White** - Labels, neutral text

### 3. Spacing and Structure

- Empty lines before/after dividers for visual separation
- Two-space indent for nested content
- Consistent alignment of key-value pairs

### 4. Actionable Feedback

Messages include next steps when applicable:
```
[✓] Debug mode enabled
[i] Restart your shell to apply changes
```

## Adding New CLI Commands

When adding new commands, follow these patterns:

```bash
_customrc_new_command() {
  echo ""
  _customrc_divider "$_CLI_PURPLE" "Command Name"
  echo ""

  # Command logic with appropriate messages
  _customrc_info "Starting operation..."

  if some_check; then
    _customrc_success "Operation completed"
  else
    _customrc_error "Operation failed"
    return 1
  fi

  echo ""
  _customrc_divider "$_CLI_PURPLE"
  echo ""
}
```

## See Also

- [styles.md](./styles.md) - Debug mode color definitions
- [logging.md](./logging.md) - Debug mode logging functions
- [customrc-cli.md](./customrc-cli.md) - Full CLI command reference
