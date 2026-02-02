#!/bin/bash

CURRENT_PATH=$(dirname "$0")
CUSTOMRC_RC_MODULES_PATH="${CURRENT_PATH}/rc-modules"
CUSTOMRC_HELPERS_PATH="${CURRENT_PATH}/helpers"

CUSTOMRC_START_TIME=$(date +%s%N)
CUSTOMRC_LOADED_COUNT=0
CUSTOMRC_IGNORED_COUNT=0

source "$CURRENT_PATH/configs.sh"
source "$CUSTOMRC_HELPERS_PATH/styles.sh"
source "$CUSTOMRC_HELPERS_PATH/logging.sh"
source "$CUSTOMRC_HELPERS_PATH/timing.sh"
source "$CUSTOMRC_HELPERS_PATH/loader.sh"


# Create temporary file for combined configuration
TEMP_COMBINED_RC=$(mktemp)
trap 'rm -f "$TEMP_COMBINED_RC"' EXIT

log_message "${INFO} ${WHITE}Initializing Customrc...${NC}"
print_divider "$PURPLE" "customrc"

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
    log_message "${CROSS}${YELLOW}Unsupported OS ${BLUE}$OS_NAME${YELLOW}, skipping OS-specific rc files${NC}"
    ;;
esac

# Source the combined configuration file
if [[ -s "$TEMP_COMBINED_RC" ]]; then
  log_message "${INFO} ${CYAN}Sourcing combined configuration...${NC}"
  source "$TEMP_COMBINED_RC"
fi

# Display initialization summary
CUSTOMRC_TOTAL_DURATION=$(get_duration_ms $CUSTOMRC_START_TIME)
print_divider "$PURPLE" "customrc"
log_message "${INFO} ${WHITE}Initialization complete${NC}"
log_message "    ${CHECK} ${WHITE}Loaded: ${GREEN}${CUSTOMRC_LOADED_COUNT}${NC}"
log_message "    ${CROSS} ${WHITE}Ignored: ${RED}${CUSTOMRC_IGNORED_COUNT}${NC}"
TOTAL_DURATION_COLOR=$(get_total_duration_color "$CUSTOMRC_TOTAL_DURATION")
log_message "    ${WARN} ${WHITE}Duration: ${TOTAL_DURATION_COLOR}${CUSTOMRC_TOTAL_DURATION}ms${NC}"

# Apply prompt positioning fix for non-Warp terminals (unless disabled)
if [[ -f "$CUSTOMRC_HELPERS_PATH/fix-prompt-at-bottom.sh" && "$TERM_PROGRAM" != "WarpTerminal" && "$CUSTOMRC_DISABLE_PROMPT_FIX_AT_BOTTOM" != "true" ]]; then
  source "$CUSTOMRC_HELPERS_PATH/fix-prompt-at-bottom.sh"
fi

# Clean up variables to prevent shell environment pollution
unset RED GREEN YELLOW BLUE PURPLE CYAN WHITE BOLD NC
unset CHECK CROSS WARN INFO
unset print_divider is_ignored add_file_to_combined get_duration_ms
unset get_duration_color get_total_duration_color log_message process_rc_directory
unset filename filepath
unset CURRENT_PATH CUSTOMRC_RC_MODULES_PATH CUSTOMRC_HELPERS_PATH
unset CUSTOMRC_START_TIME CUSTOMRC_LOADED_COUNT CUSTOMRC_IGNORED_COUNT
unset CUSTOMRC_TOTAL_DURATION TEMP_COMBINED_RC OS_NAME TOTAL_DURATION_COLOR
