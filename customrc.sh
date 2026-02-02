#!/bin/bash

CURRENT_PATH=$(dirname "$0")
CUSTOMRC_RC_MODULES_PATH="${CURRENT_PATH}/rc-modules"
CUSTOMRC_HELPERS_PATH="${CURRENT_PATH}/helpers"
CUSTOMRC_SILENT_OUTPUT=${CUSTOMRC_SILENT_OUTPUT:-false}

CUSTOMRC_START_TIME=$(date +%s%N)
CUSTOMRC_LOADED_COUNT=0
CUSTOMRC_IGNORED_COUNT=0

source "$CUSTOMRC_HELPERS_PATH/styles.sh"

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

# Calculates elapsed time in milliseconds from a start timestamp
get_duration_ms() {
  local start_time=$1
  local end_time=$(date +%s%N)
  echo $(( (end_time - start_time) / 1000000 ))
}

# Returns an ANSI color code based on individual file load duration
get_duration_color() {
  local duration=$1
  if (( duration < 10 )); then
    echo "$GREEN"
  elif (( duration < 50 )); then
    echo "$YELLOW"
  else
    echo "$RED"
  fi
}

# Returns an ANSI color code based on total initialization duration
get_total_duration_color() {
  local duration=$1
  if (( duration < 1000 )); then
    echo "$GREEN"
  elif (( duration < 2000 )); then
    echo "$YELLOW"
  else
    echo "$RED"
  fi
}

# Checks if a filename is in the provided ignore list
is_ignored() {
  local filename="$1"
  shift
  local ignore_list=("$@")

  for ignored_item in "${ignore_list[@]}"; do
    [[ "$ignored_item" == "$filename" ]] && return 0
  done
  return 1
}

# Appends a file's content to the combined script with timing instrumentation
add_file_to_combined() {
  local filepath="$1"
  local filename="$2"
  local category="$3"

  [[ ! -f "$filepath" ]] && return

  cat <<EOF >> "$TEMP_COMBINED_RC"
# === Start of $filename [$category] ===
_file_start_time=\$(date +%s%N)
EOF

  cat "$filepath" >> "$TEMP_COMBINED_RC"
  echo "" >> "$TEMP_COMBINED_RC"

  cat <<EOF >> "$TEMP_COMBINED_RC"
_file_duration=\$(get_duration_ms \$_file_start_time)
if [[ "\$CUSTOMRC_SILENT_OUTPUT" != true ]]; then
  _duration_color=\$(get_duration_color \$_file_duration)
  echo -e "${CHECK} ${WHITE}Loaded:${NC} ${BLUE}$filename ${PURPLE}[$category]${NC} (\${_duration_color}\${_file_duration}ms${NC})"
fi
# === End of $filename [$category] ===

EOF

  ((CUSTOMRC_LOADED_COUNT++))
}

# Processes all RC files in a directory, respecting the ignore list
process_rc_directory() {
  local directory="$1"
  local category="$2"
  shift 2
  local ignore_list=("$@")

  [[ ! -d "$directory" ]] && return

  for filepath in "$directory"/*; do
    local filename=$(basename "$filepath")

    if is_ignored "$filename" "${ignore_list[@]}"; then
      ((CUSTOMRC_IGNORED_COUNT++))
      log_message "${CROSS} ${WHITE}Ignored:${NC} ${BLUE}$filename ${PURPLE}[$category]${NC}"
    else
      add_file_to_combined "$filepath" "$filename" "$category"
    fi
  done
}

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

# Create temporary file for combined configuration
TEMP_COMBINED_RC=$(mktemp)
trap 'rm -f "$TEMP_COMBINED_RC"' EXIT

log_message "${INFO} ${WHITE}Initializing Customrc...${NC}"
[[ "$CUSTOMRC_SILENT_OUTPUT" != true ]] && print_divider "$PURPLE" "customrc"

# Process Global RC files
process_rc_directory \
  "$CUSTOMRC_RC_MODULES_PATH/Global" \
  "Global" \
  "${CUSTOMRC_GLOBAL_IGNORE_LIST[@]}"

# Process OS-specific RC files
OS_NAME=$(uname)
case "$OS_NAME" in
  Darwin)
    process_rc_directory \
      "$CUSTOMRC_RC_MODULES_PATH/Darwin" \
      "Darwin" \
      "${CUSTOMRC_DARWIN_IGNORE_LIST[@]}"
    ;;
  Linux)
    process_rc_directory \
      "$CUSTOMRC_RC_MODULES_PATH/Linux" \
      "Linux" \
      "${CUSTOMRC_LINUX_IGNORE_LIST[@]}"
    ;;
  *)
    echo -e "${CROSS}${YELLOW}Unsupported OS ${BLUE}$OS_NAME${YELLOW}, skipping OS-specific rc files${NC}"
    ;;
esac

# Source the combined configuration file
if [[ -s "$TEMP_COMBINED_RC" ]]; then
  log_message "${INFO} ${CYAN}Sourcing combined configuration...${NC}"
  source "$TEMP_COMBINED_RC"
fi

# Display initialization summary
CUSTOMRC_TOTAL_DURATION=$(get_duration_ms $CUSTOMRC_START_TIME)

if [[ "$CUSTOMRC_SILENT_OUTPUT" != true ]]; then
  print_divider "$PURPLE" "customrc"
  echo -e "${INFO} ${WHITE}Initialization complete${NC}"
  echo -e "    ${CHECK} ${WHITE}Loaded: ${GREEN}${CUSTOMRC_LOADED_COUNT}${NC}"
  echo -e "    ${CROSS} ${WHITE}Ignored: ${RED}${CUSTOMRC_IGNORED_COUNT}${NC}"
  TOTAL_DURATION_COLOR=$(get_total_duration_color "$CUSTOMRC_TOTAL_DURATION")
  echo -e "    ${WARN} ${WHITE}Duration: ${TOTAL_DURATION_COLOR}${CUSTOMRC_TOTAL_DURATION}ms${NC}"
  echo ""
fi

# Apply prompt positioning fix for non-Warp terminals
if [[ -f "$CUSTOMRC_HELPERS_PATH/fix-prompt-at-bottom.sh" && "$TERM_PROGRAM" != "WarpTerminal" ]]; then
  source "$CUSTOMRC_HELPERS_PATH/fix-prompt-at-bottom.sh"
fi

# Clean up variables to prevent shell environment pollution
unset RED GREEN YELLOW BLUE PURPLE CYAN WHITE BOLD NC
unset CHECK CROSS WARN INFO
unset print_divider is_ignored add_file_to_combined get_duration_ms
unset get_duration_color get_total_duration_color log_message process_rc_directory
unset filename filepath
