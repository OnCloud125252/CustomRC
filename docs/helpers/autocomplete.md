# Autocomplete Helper

The `autocomplete.sh` helper provides shell tab completion for the `customrc` CLI, auto-detecting the user's shell and generating appropriate completion scripts for Bash and Zsh.

## Location

```
helpers/autocomplete.sh       # Core autocomplete library
helpers/autocomplete-cli.sh   # CLI command integration
```

## Overview

This helper enables intelligent tab completion for the `customrc` command and its subcommands. It provides:

- **Shell auto-detection** - Automatically detects Bash or Zsh
- **Completion generation** - Generates native completion scripts for each shell
- **User-local installation** - Prefers user directories to avoid requiring `sudo`
- **One-time prompt** - Offers installation on first use without being intrusive

The completion scripts support:
- Top-level commands (`sync`, `cache`, `modules`, etc.)
- Subcommands per command (`sync init|push|pull|status`)
- Dynamic module name completion for `modules edit`

## Architecture

### File Structure

```
helpers/
├── autocomplete.sh       # Core functions (detection, generation, installation)
└── autocomplete-cli.sh   # CLI command dispatcher
```

### Flow

1. **Shell startup** → `customrc.sh` sources CLI, which sources `autocomplete-cli.sh`
2. **Auto-prompt check** → Runs in background subshell, shows one-time message if needed
3. **User runs `customrc complete install`** → Calls `autocomplete_install()`
4. **Shell detection** → `_autocomplete_detect_shell()` returns `bash` or `zsh`
5. **Directory selection** → `_autocomplete_get_completion_dir()` picks writable location
6. **Script generation** → Generates completion script inline (not from external files)
7. **Installation** → Writes to appropriate directory, sets permissions

## Core Functions

### `_autocomplete_detect_shell()`

Detects the current shell type using `$BASH_VERSION` and `$SHELL`.

```bash
local shell_type=$(_autocomplete_detect_shell)
# Returns: "bash", "zsh", or "unknown"
```

**Detection logic:**
- If `$BASH_VERSION` is set → returns `bash`
- If `$(basename "$SHELL")` is `zsh` or `$ZSH_VERSION` is set → returns `zsh`
- Otherwise → returns `unknown`

### `_autocomplete_get_completion_dir()`

Returns the appropriate completion directory for the shell.

```bash
local completion_dir=$(_autocomplete_get_completion_dir [shell_type])
```

**Directory preference (in order):**

| Shell | Preferred Location | Fallback |
|-------|-------------------|----------|
| Bash | `~/.bash_completion.d/` | `/usr/local/etc/bash_completion.d/` |
| Zsh | `~/.oh-my-zsh/custom/completions/` | `~/.zsh/completions/` |

User-local directories are preferred to avoid permission issues on macOS (SIP) and other systems where system directories are protected.

### `_autocomplete_get_bash_completions()`

Generates the Bash completion script. Outputs to stdout.

**Generated script features:**
- Uses `complete -F` with a custom completion function
- Completes top-level commands: `sync`, `cache`, `modules`, `debug`, `update`, `status`, `doctor`, `version`, `help`, `complete`
- Context-aware subcommand completion per command
- Dynamic module name completion for `modules edit`

### `_autocomplete_get_zsh_completions()`

Generates the Zsh completion script. Outputs to stdout.

**Generated script features:**
- Uses `#compdef customrc` for Zsh's completion system
- `_arguments` for command-line parsing
- `_describe` for rich completion with descriptions
- Context-aware subcommand handling with state machine
- Module name completion using glob expansion `(N)`

## Public API

### `autocomplete_install()`

Installs completions for the detected shell.

```bash
autocomplete_install
```

**Behavior:**
1. Detects shell type
2. Gets completion directory
3. Creates directory if needed
4. Checks write permissions
5. Generates and writes completion script
6. Sets file permissions (644)
7. Marks auto-check as completed

**Error handling:**
- Returns `1` if shell type is unknown
- Returns `1` if directory cannot be created
- Returns `1` if permission denied (with helpful message)
- Returns `1` if file cannot be written

**Example output:**
```
[✓] Installed zsh completions to: /Users/you/.zsh/completions/_customrc
[i] Restart your shell or source your rc file to activate completions
```

### `autocomplete_status()`

Shows completion installation status.

```bash
autocomplete_status
```

Displays:
- Detected shell type
- Completion directory path
- Installation status (installed/not installed)
- Installed file location (if applicable)

### `autocomplete_uninstall()`

Removes completions for the current shell.

```bash
autocomplete_uninstall
```

Uses `trash` if available, falls back to `rm -f`.

### `autocomplete_check_and_offer()`

One-time auto-prompt on first shell startup.

```bash
autocomplete_check_and_offer
```

**Behavior:**
- Skips if already checked (flag file exists)
- Skips if shell type is unknown
- Skips if completions are already installed
- Shows one-time message suggesting `customrc complete install`
- Marks check as completed

**Flag file:** `${CUSTOMRC_CACHE_DIR:-$HOME/.cache/customrc}/.autocomplete_checked`

## CLI Integration

The `autocomplete-cli.sh` file provides the `customrc complete` command interface.

### Commands

| Command | Function called |
|---------|-----------------|
| `customrc complete install` | `autocomplete_install` |
| `customrc complete status` | `autocomplete_status` |
| `customrc complete uninstall` | `autocomplete_uninstall` |
| `customrc complete help` | Shows help |

### Integration in `customrc-cli.sh`

```bash
# At end of customrc-cli.sh
source "${CUSTOMRC_HELPERS_PATH}/autocomplete-cli.sh"
```

## Completion Script Details

### Bash Completion

Uses the `complete` builtin with a function:

```bash
complete -F _customrc_complete customrc
```

The completion function:
- Accesses `COMP_WORDS` array for command-line parsing
- Uses `compgen -W` for word list generation
- Handles different positions (command vs subcommand)

### Zsh Completion

Uses Zsh's native completion system:

```bash
#compdef customrc
```

Key features:
- `_arguments -C` for context-sensitive completion
- State machine for command/subcommand handling
- `_describe` for rich descriptions
- Glob qualifiers `(N)` for safe module enumeration

## Module Name Completion

Both completion scripts dynamically enumerate modules from `rc-modules/`:

```bash
local modules_path="${CUSTOMRC_PATH:-$HOME/.customrc}/rc-modules"
for dir in Global Darwin Linux; do
  for f in "$modules_path/$dir"/*.sh; do
    # Add module names with and without category prefix
    modules+=("$dir/$(basename "$f" .sh)")
    modules+=("$(basename "$f" .sh)")
  done
done
```

This allows completion like:
```
customrc modules edit docker<TAB>
# Completes to: docker, Global/docker
customrc modules edit Global/<TAB>
# Shows: Global/aliases, Global/docker, ...
```

## Auto-Prompt on Shell Startup

In `customrc.sh`:

```bash
if [[ $- == *i* ]]; then
  (
    source "$CUSTOMRC_HELPERS_PATH/autocomplete.sh" && \
    autocomplete_check_and_offer
  ) &
  disown 2>/dev/null || true
fi
```

**Design decisions:**
- Runs in subshell to isolate errors
- Runs in background (`&`) to not block startup
- `disown` prevents job status messages
- Only in interactive shells (`[[ $- == *i* ]]`)
- Errors suppressed (`2>/dev/null`)

## Performance Considerations

- **Generation is fast** (< 10ms) - scripts are generated inline, not read from files
- **Auto-check is async** - runs in background, doesn't delay shell startup
- **Flag file prevents repeated checks** - one-time per shell session
- **No external dependencies** - pure shell implementation

## Modifying Completions

To add a new command or subcommand:

1. **Update both generators** - Edit both `_autocomplete_get_bash_completions` and `_autocomplete_get_zsh_completions`

2. **Add to command list** - Include in the top-level commands array

3. **Add subcommand handling** - Add case for the new command in the subcommand switch

4. **Update CLI help** - Add to `docs/helpers/customrc-cli.md`

Example - adding a `backup` command:

```bash
# In _autocomplete_get_bash_completions
local commands="sync cache modules debug update status doctor version help complete backup"

case "$cmd" in
  backup)
    local subcommands="create restore list"
    COMPREPLY=($(compgen -W "$subcommands" -- "$cur"))
    ;;
esac

# In _autocomplete_get_zsh_completions
local -a commands
commands+=(
  'backup:Manage configuration backups'
)

case "$line[1]" in
  backup)
    local -a backup_cmds
    backup_cmds=(
      'create:Create a new backup'
      'restore:Restore from backup'
      'list:List available backups'
    )
    _describe -t backup_cmds 'backup subcommands' backup_cmds
    ;;
esac
```

## Testing

Test completion generation:

```bash
# Test shell detection
source helpers/autocomplete.sh
_autocomplete_detect_shell

# Test completion output
_autocomplete_get_bash_completions
_autocomplete_get_zsh_completions

# Test installation (dry run)
autocomplete_status
```

## See Also

- [customrc-cli.md](./customrc-cli.md) - User-facing CLI documentation
- [../user-guide.md](../user-guide.md) - User guide
