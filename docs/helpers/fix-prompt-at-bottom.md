# Fix Prompt at Bottom Helper

The `fix-prompt-at-bottom.sh` helper ensures the shell prompt always appears at the bottom of the terminal window.

## Location

```
helpers/fix-prompt-at-bottom.sh
```

## Overview

This helper solves a common terminal UX issue: when you open a new terminal or clear the screen, the prompt appears at the top, leaving unused space below. This helper pushes the prompt to the bottom of the terminal for a cleaner, more consistent experience.

## How It Works

The helper uses a simple technique:

1. Creates an alias `_clear` pointing to the real `/usr/bin/clear`
2. Overrides the `clear` function to:
   - Clear the screen
   - Print enough newlines to push the prompt to the bottom
3. Executes the same newline printing on shell startup

```bash
alias _clear="/usr/bin/clear"
clear() {
  _clear
  printf '\n%.0s' {1..$(($(tput lines) - 2))}
}
printf '\n%.0s' {1..$(($(tput lines) - 2))}
```

## Visual Example

**Without this helper:**
```
┌────────────────────────────────┐
│ $ _                            │  ← Prompt at top
│                                │
│                                │
│                                │
│                                │  ← Wasted space
│                                │
└────────────────────────────────┘
```

**With this helper:**
```
┌────────────────────────────────┐
│                                │
│                                │
│                                │
│                                │
│                                │
│ $ _                            │  ← Prompt at bottom
└────────────────────────────────┘
```

## Functions

### `clear` (override)

Clears the screen and positions the prompt at the bottom.

```bash
clear
```

This replaces the default `clear` command behavior.

### `_clear` (alias)

Direct access to the original `/usr/bin/clear` if you need it.

```bash
_clear  # Standard clear behavior
```

## Technical Details

- `$(tput lines)` returns the terminal height in rows
- Subtracts 2 to leave room for the prompt line and cursor
- `printf '\n%.0s' {1..N}` prints N newlines efficiently

## Compatibility

This helper works with:
- zsh (primary target)
- Most terminal emulators (iTerm2, Terminal.app, Alacritty, etc.)

## Disabling

To disable this behavior, add the file to your ignore list in `configs.sh`:

```bash
CUSTOMRC_GLOBAL_IGNORE_LIST=(
  "fix-prompt-at-bottom.sh"
  # ... other ignored files
)
```

## See Also

- [loader.md](./loader.md) - How modules are loaded
