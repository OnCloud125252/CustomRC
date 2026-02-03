# macOS-Specific Aliases
# Aliases that only work on macOS (Darwin)
#
# Usage: Uncomment and customize the examples below, or add your own aliases.
# These will be loaded automatically on macOS systems.

# ─────────────────────────────────────────────────────────────────────────────
# Finder Integration
# ─────────────────────────────────────────────────────────────────────────────

# Open current directory in Finder
# alias o="open ."

# Show/hide hidden files in Finder
# alias showfiles="defaults write com.apple.finder AppleShowAllFiles -bool true && killall Finder"
# alias hidefiles="defaults write com.apple.finder AppleShowAllFiles -bool false && killall Finder"

# ─────────────────────────────────────────────────────────────────────────────
# macOS Utilities
# ─────────────────────────────────────────────────────────────────────────────

# Lock screen
# alias afk="pmset displaysleepnow"

# Empty trash
# alias emptytrash="sudo rm -rfv /Volumes/*/.Trashes; sudo rm -rfv ~/.Trash; sudo rm -rfv /private/var/log/asl/*.asl"

# Flush DNS cache
# alias flushdns="sudo dscacheutil -flushcache; sudo killall -HUP mDNSResponder"

# ─────────────────────────────────────────────────────────────────────────────
# Application Shortcuts
# ─────────────────────────────────────────────────────────────────────────────

# alias chrome="open -a 'Google Chrome'"
# alias safari="open -a Safari"

# ─────────────────────────────────────────────────────────────────────────────
# Add your custom macOS aliases below
# ─────────────────────────────────────────────────────────────────────────────
