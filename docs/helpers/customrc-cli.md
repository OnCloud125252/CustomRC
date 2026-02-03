# CLI Helper

The `customrc-cli.sh` helper provides a git-style command-line interface for managing the CustomRC shell configuration system.

## Location

```
helpers/customrc-cli.sh
```

## Overview

This helper adds the `customrc` command to your shell, providing subcommands for managing modules, caches, debug mode, and syncing configurations across machines. Unlike other helpers that are unset after initialization, CLI functions remain available for interactive use.

## Commands

### `customrc help`

Displays help information for all commands or a specific command.

```bash
customrc help [command]
```

**Usage:**
```bash
# Show all commands
customrc help

# Show help for a specific command
customrc help sync
customrc help modules
customrc help cache
```

### `customrc version`

Shows the current CustomRC version.

```bash
customrc version
```

**Example Output:**
```
customrc 1.0.0
```

### `customrc status`

Displays an overall status summary of the CustomRC installation.

```bash
customrc status
```

**Example Output:**
```
━━━━[CustomRC Status]━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  Version:     1.0.0
  Path:        /Users/you/.customrc
  Modules:     /Users/you/.customrc/rc-modules
  Cache:       /Users/you/.cache/customrc
  Debug:       disabled
  Sync:        git (branch: main, 0 uncommitted)
  Modules:     Global: 12, Darwin: 5, Linux: 0

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### `customrc doctor`

Runs health checks to identify configuration issues.

```bash
customrc doctor
```

**Checks performed:**
| Check | Description |
|-------|-------------|
| CustomRC directory | Verifies `CUSTOMRC_PATH` exists |
| rc-modules directory | Verifies modules directory exists |
| Required helpers | Checks for `cache.sh` and `monolithic.sh` |
| Module syntax | Validates all `.sh` files with `bash -n` |
| Cache directory | Verifies cache directory is writable |
| configs.sh | Confirms configuration file exists |

**Example Output:**
```
━━━━[CustomRC Doctor]━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

[✓] CustomRC directory exists: /Users/you/.customrc
[✓] rc-modules directory exists
[✓] Helper found: cache.sh
[✓] Helper found: monolithic.sh

[i] Checking module syntax...
[✓] All modules have valid syntax

[✓] Cache directory is writable
[✓] configs.sh exists

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

[✓] All checks passed!
```

## Sync Commands

Manage git synchronization of your `rc-modules` directory.

### `customrc sync init`

Initializes rc-modules as a git repository or clones from a URL.

```bash
customrc sync init [url]
```

**Usage:**
```bash
# Initialize as new git repo
customrc sync init

# Clone from remote URL (backs up existing rc-modules first)
customrc sync init https://github.com/you/my-shell-config.git
```

### `customrc sync push`

Pushes rc-modules changes to the remote repository.

```bash
customrc sync push
```

### `customrc sync pull`

Pulls latest rc-modules from the remote repository.

```bash
customrc sync pull
```

### `customrc sync status`

Shows git status of the rc-modules directory.

```bash
customrc sync status
```

## Cache Commands

Manage the monolithic cache and tool caches.

### `customrc cache status`

Displays cache status including size, age, and line count.

```bash
customrc cache status
```

**Example Output:**
```
Cache Status:

  Monolithic cache:
    Path:    /Users/you/.cache/customrc/monolithic.sh
    Size:    20 KB
    Lines:   627
    Created: 2 hours ago
```

### `customrc cache clear`

Clears all caches or a specific cache.

```bash
customrc cache clear [name]
```

**Usage:**
```bash
# Clear all caches
customrc cache clear

# Clear specific cache
customrc cache clear starship
```

### `customrc cache rebuild`

Forces regeneration of the monolithic cache.

```bash
customrc cache rebuild
```

This clears the existing monolithic cache and regenerates it by re-sourcing all modules.

## Modules Commands

Manage shell configuration modules.

### `customrc modules list`

Lists all modules with their load status.

```bash
customrc modules list
```

**Example Output:**
```
Modules:

  Global/
    ✓ aliases.sh
    ✓ functions.sh
    ✓ fzf.sh
    ✗ nvm.sh (ignored)

  Darwin/
    ✓ brew.sh
    ✗ iterm.sh (ignored)
```

### `customrc modules edit`

Opens a module in your editor.

```bash
customrc modules edit <name>
```

**Usage:**
```bash
# Edit by filename (searches all directories)
customrc modules edit docker.sh
customrc modules edit docker  # .sh extension is optional
```

The command searches `Global/`, `Darwin/`, and `Linux/` directories for the module.

### `customrc modules new`

Creates a new module from a template.

```bash
customrc modules new <category/name>
customrc modules new <name>  # defaults to Global/
```

**Usage:**
```bash
# Create in Global directory
customrc modules new my-aliases

# Create in specific category
customrc modules new Darwin/macos-utils
customrc modules new Linux/linux-tools
```

**Template generated:**
```bash
# my-aliases
# CustomRC module - Global
# Created: 2024-01-15

# Add your aliases, functions, and configurations below

```

The module opens in your `$EDITOR` after creation.

## Debug Commands

Toggle debug mode for troubleshooting.

### `customrc debug status`

Shows current debug mode status.

```bash
customrc debug status
```

### `customrc debug on`

Enables debug mode in `configs.sh`.

```bash
customrc debug on
```

After enabling, restart your shell to see verbose output with timing information.

### `customrc debug off`

Disables debug mode in `configs.sh`.

```bash
customrc debug off
```

## Internal Functions

These functions are used internally by the CLI:

| Function | Purpose |
|----------|---------|
| `_customrc_info` | Prints info message with `[i]` prefix |
| `_customrc_success` | Prints success message with `[✓]` prefix |
| `_customrc_warn` | Prints warning message with `[!]` prefix |
| `_customrc_error` | Prints error message with `[✗]` prefix |
| `_customrc_get_path` | Returns CustomRC installation path |
| `_customrc_get_modules_path` | Returns rc-modules directory path |
| `_customrc_get_helpers_path` | Returns helpers directory path |
| `_customrc_get_cache_path` | Returns cache directory path |

## Examples

### Setting Up Sync

```bash
# Initialize your rc-modules as a git repo
customrc sync init

# Add remote and push
cd ~/.customrc/rc-modules
git remote add origin https://github.com/you/my-shell-config.git
git add -A && git commit -m "Initial commit"
customrc sync push
```

### On a New Machine

```bash
# After installing CustomRC, clone your modules
customrc sync init https://github.com/you/my-shell-config.git
```

### Debugging Slow Startup

```bash
# Enable debug mode
customrc debug on

# Restart shell to see timing
exec $SHELL

# After identifying slow modules, disable debug
customrc debug off
```

### Creating a New Module

```bash
# Create and edit a new module
customrc modules new Global/docker

# View all modules
customrc modules list
```

## See Also

- [caching.md](./caching.md) - Cache system details
- [monolithic.md](./monolithic.md) - Monolithic cache generation
- [../user-guide.md](../user-guide.md) - User guide
- [../configuration.md](../configuration.md) - Configuration options
