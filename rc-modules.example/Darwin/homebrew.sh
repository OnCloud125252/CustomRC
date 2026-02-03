# Homebrew Configuration
# Setup for Homebrew package manager on macOS
#
# Usage: Uncomment the sections you need. The path setup is required
# for Homebrew to work correctly.

# ─────────────────────────────────────────────────────────────────────────────
# Homebrew Path Setup (Required)
# ─────────────────────────────────────────────────────────────────────────────

# Apple Silicon Macs (M1/M2/M3)
# if [[ -f "/opt/homebrew/bin/brew" ]]; then
#   eval "$(/opt/homebrew/bin/brew shellenv)"
# fi

# Intel Macs
# if [[ -f "/usr/local/bin/brew" ]]; then
#   eval "$(/usr/local/bin/brew shellenv)"
# fi

# ─────────────────────────────────────────────────────────────────────────────
# Homebrew Aliases
# ─────────────────────────────────────────────────────────────────────────────

# alias bup="brew update && brew upgrade"
# alias bclean="brew cleanup -s && brew autoremove"
# alias bout="brew outdated"

# ─────────────────────────────────────────────────────────────────────────────
# Homebrew Completions (for zsh)
# ─────────────────────────────────────────────────────────────────────────────

# if type brew &>/dev/null; then
#   FPATH="$(brew --prefix)/share/zsh/site-functions:${FPATH}"
#   autoload -Uz compinit && compinit
# fi

# ─────────────────────────────────────────────────────────────────────────────
# Add your custom Homebrew configuration below
# ─────────────────────────────────────────────────────────────────────────────
