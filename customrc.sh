#!/bin/bash

CURRENT_PATH=$(dirname "$0")
CUSTOMRC_RC_MODULES_PATH="${CURRENT_PATH}/rc-modules"
CUSTOMRC_HELPERS_PATH="${CURRENT_PATH}/helpers"

# Save current monitor mode state and disable job notifications during init
_CUSTOMRC_PREVIOUS_MONITOR_STATE=$-
set +m

# Read version from dedicated file (repo-managed, not user config)
CUSTOMRC_VERSION=$(cat "$CURRENT_PATH/version" 2>/dev/null || echo "unknown")

source "$CURRENT_PATH/configs.sh" 2>/dev/null

# Validate ignore lists exist (warn if missing and initialize as empty)
_validate_ignore_lists() {
  local warn_prefix="\033[33m[CustomRC Warning]\033[0m"
  local missing=()

  if [[ -z "${CUSTOMRC_GLOBAL_IGNORE_LIST+defined}" ]]; then
    missing+=("CUSTOMRC_GLOBAL_IGNORE_LIST")
    CUSTOMRC_GLOBAL_IGNORE_LIST=()
  fi

  if [[ -z "${CUSTOMRC_DARWIN_IGNORE_LIST+defined}" ]]; then
    missing+=("CUSTOMRC_DARWIN_IGNORE_LIST")
    CUSTOMRC_DARWIN_IGNORE_LIST=()
  fi

  if [[ -z "${CUSTOMRC_LINUX_IGNORE_LIST+defined}" ]]; then
    missing+=("CUSTOMRC_LINUX_IGNORE_LIST")
    CUSTOMRC_LINUX_IGNORE_LIST=()
  fi

  if [[ ${#missing[@]} -gt 0 ]]; then
    echo -e "${warn_prefix} Missing ignore lists in configs.sh:"
    for name in "${missing[@]}"; do
      echo -e "  - ${name}"
    done
    echo -e "${warn_prefix} These have been initialized as empty arrays."
  fi
}
_validate_ignore_lists
unset _validate_ignore_lists

# Load CLI (available in both debug and production modes)
source "$CUSTOMRC_HELPERS_PATH/customrc-cli.sh"

# Check for autocomplete (one-time prompt, runs after a short delay to not block startup)
# Only in interactive shells
if [[ $- == *i* ]]; then
  (
    # Run in subshell to isolate any errors
    source "$CUSTOMRC_HELPERS_PATH/autocomplete.sh" 2>/dev/null && \
    autocomplete_check_and_offer 2>/dev/null
  ) &
  disown 2>/dev/null || true
fi

# Check if rc-modules directory exists
if [[ ! -d "$CUSTOMRC_RC_MODULES_PATH" ]]; then
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "CustomRC: rc-modules/ directory not found"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  echo "Run the installer to set up your modules:"
  echo "  ${CURRENT_PATH}/install.sh"
  echo ""
  echo "Or manually copy the template:"
  echo "  cp -r ${CURRENT_PATH}/rc-modules.example ${CURRENT_PATH}/rc-modules"
  echo ""
  return 1 2>/dev/null || exit 1
fi

if [[ "$CUSTOMRC_DEBUG_MODE" == true ]]; then
  # Debug mode: verbose output with timing instrumentation
  CUSTOMRC_START_TIME=$(date +%s%N)
  CUSTOMRC_LOADED_COUNT=0
  CUSTOMRC_IGNORED_COUNT=0
  CUSTOMRC_TERMINAL_WIDTH=${COLUMNS:-$(tput cols 2>/dev/null || echo 80)}

  source "$CUSTOMRC_HELPERS_PATH/styles.sh"
  source "$CUSTOMRC_HELPERS_PATH/logging.sh"
  source "$CUSTOMRC_HELPERS_PATH/timing.sh"
  source "$CUSTOMRC_HELPERS_PATH/cache.sh"
  source "$CUSTOMRC_HELPERS_PATH/loader.sh"

  # Show debug mode warning
  log_message "${WARN} ${YELLOW}Debug mode enabled - Performance will be slower${NC}"
  log_message "    ${WHITE}Run customrc debug off to disable debug mode${NC}"

  # Create temporary file for combined configuration
  TEMP_COMBINED_RC=$(mktemp)
  trap 'command rm -f "$TEMP_COMBINED_RC"' EXIT

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
  get_duration_ms $CUSTOMRC_START_TIME CUSTOMRC_TOTAL_DURATION
  print_divider "$PURPLE" "customrc"
  log_message "${INFO} ${WHITE}Initialization complete${NC}"
  log_message "    ${CHECK} ${WHITE}Loaded: ${GREEN}${CUSTOMRC_LOADED_COUNT}${NC}"
  log_message "    ${CROSS} ${WHITE}Ignored: ${RED}${CUSTOMRC_IGNORED_COUNT}${NC}"
  get_total_duration_color "$CUSTOMRC_TOTAL_DURATION" TOTAL_DURATION_COLOR
  log_message "    ${WARN} ${WHITE}Duration: ${TOTAL_DURATION_COLOR}${CUSTOMRC_TOTAL_DURATION}ms${NC}"

  # Clean up debug mode variables
  unset RED GREEN YELLOW BLUE PURPLE CYAN WHITE BOLD NC
  unset CHECK CROSS WARN INFO
  unset print_divider is_ignored add_file_to_combined get_duration_ms
  unset get_duration_color get_total_duration_color log_message process_rc_directory
  unset _cache_ttl_to_seconds _cache_is_expired _cache_binary_newer _cache_write_meta _cache_read_meta
  unset cache_init cache_get CUSTOMRC_CACHE_DIR CUSTOMRC_CACHE_META_DIR
  unset filename filepath
  unset CUSTOMRC_START_TIME CUSTOMRC_LOADED_COUNT CUSTOMRC_IGNORED_COUNT CUSTOMRC_TERMINAL_WIDTH
  unset CUSTOMRC_TOTAL_DURATION TEMP_COMBINED_RC OS_NAME TOTAL_DURATION_COLOR
else
  # Production mode: use cached monolithic file for maximum performance
  source "$CUSTOMRC_HELPERS_PATH/cache.sh"
  source "$CUSTOMRC_HELPERS_PATH/monolithic.sh"

  if _monolithic_needs_rebuild "$CUSTOMRC_MONOLITHIC_CACHE"; then
    generate_monolithic_file "$CUSTOMRC_MONOLITHIC_CACHE"
  fi

  source "$CUSTOMRC_MONOLITHIC_CACHE"

  # Clean up production mode variables
  unset _monolithic_needs_rebuild _append_modules_from_dir generate_monolithic_file
  unset CUSTOMRC_MONOLITHIC_CACHE
  unset _cache_ttl_to_seconds _cache_is_expired _cache_binary_newer _cache_write_meta _cache_read_meta
  unset cache_init cache_get CUSTOMRC_CACHE_DIR CUSTOMRC_CACHE_META_DIR
fi

# Apply prompt positioning fix for non-Warp terminals (unless disabled)
if [[ -f "$CUSTOMRC_HELPERS_PATH/fix-prompt-at-bottom.sh" && "$TERM_PROGRAM" != "WarpTerminal" && "$CUSTOMRC_PROMPT_FIX_AT_BOTTOM" == "true" ]]; then
  source "$CUSTOMRC_HELPERS_PATH/fix-prompt-at-bottom.sh"
fi

# Restore previous monitor mode state (if it was enabled)
if [[ "$_CUSTOMRC_PREVIOUS_MONITOR_STATE" == *m* ]]; then
  set -m
fi
unset _CUSTOMRC_PREVIOUS_MONITOR_STATE

# Clean up common variables
unset CURRENT_PATH CUSTOMRC_RC_MODULES_PATH CUSTOMRC_HELPERS_PATH
