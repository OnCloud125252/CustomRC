CUSTOMRC_VERSION="1.0.0"

CUSTOMRC_DEBUG_MODE=false

CUSTOMRC_PROMPT_FIX_AT_BOTTOM=true

# Disable prompt fix at bottom in debug mode for better readability
[[ "$CUSTOMRC_DEBUG_MODE" == true ]] && CUSTOMRC_PROMPT_FIX_AT_BOTTOM=false

# Global ignore list (applies to all platforms)
CUSTOMRC_GLOBAL_IGNORE_LIST=(
  zoxide.sh
  podman.sh
  python-virtual-environment.sh
  nvm.sh
  thefuck.sh
)

# Platform-specific ignore lists
CUSTOMRC_DARWIN_IGNORE_LIST=(
  cursor.sh
  iterm.sh
  jankyborders.sh
  dnslookup.sh
)

CUSTOMRC_LINUX_IGNORE_LIST=()