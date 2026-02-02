CUSTOMRC_SILENT_OUTPUT=${CUSTOMRC_SILENT_OUTPUT:-false}
CUSTOMRC_DISABLE_PROMPT_FIX_AT_BOTTOM=${CUSTOMRC_DISABLE_PROMPT_FIX_AT_BOTTOM:-false}

# Global ignore list (applies to all platforms)
CUSTOMRC_GLOBAL_IGNORE_LIST=(
  "zoxide.sh"
  "podman.sh"
  "python-virtual-environment.sh"
  "nvm.sh"
  "thefuck.sh"
)

# Platform-specific ignore lists
CUSTOMRC_DARWIN_IGNORE_LIST=(
  "cursor.sh"
  "iterm.sh"
  "jankyborders.sh"
  "dnslookup.sh"
)

CUSTOMRC_LINUX_IGNORE_LIST=()