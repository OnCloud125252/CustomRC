# Prints a full-width divider line with a centered label
print_divider() {
  [[ "$CUSTOMRC_DEBUG_MODE" != true ]] && return
  local color="${1:-$PURPLE}" label="${2:-customrc}"
  local terminal_width=${CUSTOMRC_TERMINAL_WIDTH:-80}
  local padding_width=$((terminal_width - ${#label} - 6))
  local spaces
  printf -v spaces '%*s' "$padding_width" ''
  printf '%b━━━━[%s]%s%b\n' "$color" "$label" "${spaces// /━}" "$NC"
}

# Logs a message only when silent mode is disabled
log_message() {
  [[ "$CUSTOMRC_DEBUG_MODE" != true ]] && return
  echo -e "$1"
}
