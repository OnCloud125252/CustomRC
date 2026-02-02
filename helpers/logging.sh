# Prints a full-width divider line with a centered label
print_divider() {
  local color="${1:-$PURPLE}"
  local label="${2:-customrc}"
  local terminal_width=$(tput cols 2>/dev/null || echo 80)
  local padding_width=$((terminal_width - ${#label} - 6))
  printf "${color}━━━━[${label}]%${padding_width}s${NC}\\n" | tr ' ' '━'
}

# Logs a message only when silent mode is disabled
log_message() {
  [[ "$CUSTOMRC_SILENT_OUTPUT" == true ]] && return
  echo -e "$1"
}
