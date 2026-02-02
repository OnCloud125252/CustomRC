#!/bin/bash

# =============================================================================
# Configuration & Styles
# =============================================================================

# Basic Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[0;37m'

# Text Styles
BOLD='\033[1m'
NC='\033[0m' # No Color

# Symbols
CHECK="[✓]"
CROSS="[✗]"
WARN="[!]"
INFO="[i]"
ROCKET='\xF0\x9F\x9A\x80'

CURRENT_PATH=$(dirname "$0")
CUSTOMRC_SILENT_OUTPUT=${CUSTOMRC_SILENT_OUTPUT:-false}

# Initialize timing and counters
CUSTOMRC_START_TIME=$(date +%s%N)
CUSTOMRC_LOADED_COUNT=0
CUSTOMRC_IGNORED_COUNT=0
CUSTOMRC_SLOW_THRESHOLD_MS=100

# Function to print a full-width line
print_divider() {
    local color="${1:-$PURPLE}"
    local label="${2:-customrc}"
    local width=$(($(tput cols 2>/dev/null || echo 80) - ${#label} - 6))
    printf "${color}━━━━[${label}]%${width}s${NC}\n" | tr ' ' '━'
}

if [[ "$CUSTOMRC_SILENT_OUTPUT" != true ]]; then
  echo -e "${PURPLE}${ROCKET}${NC} ${PURPLE}Launching Customrc...${NC}"
  print_divider "$PURPLE" "customrc"
fi

CUSTOMRC_GLOBAL_IGNORE_LIST=(
  "zoxide.sh"
  "podman.sh"
  "python-virtual-environment.sh"
  "nvm.sh"
  "thefuck.sh"
)
CUSTOMRC_Darwin_IGNORE_LIST=(
  "cursor.sh"
  "iterm.sh"
  "jankyborders.sh"
  "dnslookup.sh"
)
CUSTOMRC_Linux_IGNORE_LIST=(
)

is_ignored() {
  local item="$1"
  local ignoreList=("${@:2}")
  for ignore in "${ignoreList[@]}"; do
    if [[ "$ignore" == "$item" ]]; then
      return 0
    fi
  done
  return 1
}

# Function to calculate duration in milliseconds
get_duration_ms() {
  local start_time=$1
  local end_time=$(date +%s%N)
  echo $(( (end_time - start_time) / 1000000 ))
}

# Create temporary file for combined content
TEMP_COMBINED_RC=$(mktemp)
trap "rm -f $TEMP_COMBINED_RC" EXIT

# Function to add file content to combined script
add_file_to_combined() {
  local file="$1"
  local fileName="$2"
  local category="$3"

  if [[ -f "$file" ]]; then
    echo "# === Start of $fileName [$category] ===" >> "$TEMP_COMBINED_RC"
    # Inject start time capture
    echo "_file_start_time=\$(date +%s%N)" >> "$TEMP_COMBINED_RC"

    # Add file content
    cat "$file" >> "$TEMP_COMBINED_RC"
    echo "" >> "$TEMP_COMBINED_RC"

    # Inject duration calculation and reporting
    # We use HEREDOC to handle variable expansion:
    # $fileName, $category, $GREEN, etc -> expanded NOW
    # \$_file_start_time, \$CUSTOMRC_SILENT_OUTPUT -> expanded LATER (in generated script)
    cat <<EOF >> "$TEMP_COMBINED_RC"
_file_duration=\$(get_duration_ms \$_file_start_time)
if [[ "\$CUSTOMRC_SILENT_OUTPUT" != true ]]; then
  echo -e "${GREEN}${CHECK}${NC} ${WHITE}Loaded:${NC} ${BLUE}$fileName ${MAGENTA}[$category]${NC} (${YELLOW}\${_file_duration}ms${NC})"
fi
EOF

    echo "# === End of $fileName [$category] ===" >> "$TEMP_COMBINED_RC"
    echo "" >> "$TEMP_COMBINED_RC"
    ((CUSTOMRC_LOADED_COUNT++))
  fi
}

# Process Global files
CUSTOMRC_GLOBAL_RC_PATH="$CUSTOMRC_PATH/Global"
if [[ -d "$CUSTOMRC_GLOBAL_RC_PATH" ]]; then
  for file in "$CUSTOMRC_GLOBAL_RC_PATH"/*; do
    fileName=$(basename "$file")
    if ! is_ignored "$fileName" "${CUSTOMRC_GLOBAL_IGNORE_LIST[@]}"; then
      add_file_to_combined "$file" "$fileName" "global"
    else
      ((CUSTOMRC_IGNORED_COUNT++))
      if [[ "$CUSTOMRC_SILENT_OUTPUT" != true ]]; then
        echo -e "${RED}${CROSS}${NC} ${WHITE}Ignored:${NC} ${BLUE}$fileName ${MAGENTA}[global]${NC}"
      fi
    fi
  done
fi

# Process OS-specific files
OS_NAME=$(uname)
if [[ $OS_NAME == "Darwin" || $OS_NAME == "Linux" ]]; then
  if [[ $OS_NAME == "Darwin" ]]; then
    CUSTOMRC_OS_IGNORE_LIST=("${CUSTOMRC_Darwin_IGNORE_LIST[@]}")
  elif [[ $OS_NAME == "Linux" ]]; then
    CUSTOMRC_OS_IGNORE_LIST=("${CUSTOMRC_Linux_IGNORE_LIST[@]}")
  fi

  CUSTOMRC_RC_PATH="$CUSTOMRC_PATH/$OS_NAME"
  if [[ -d "$CUSTOMRC_RC_PATH" ]]; then
    for file in "$CUSTOMRC_RC_PATH"/*; do
      fileName=$(basename "$file")
      if ! is_ignored "$fileName" "${CUSTOMRC_OS_IGNORE_LIST[@]}"; then
        add_file_to_combined "$file" "$fileName" "$OS_NAME"
      else
        ((CUSTOMRC_IGNORED_COUNT++))
        if [[ "$CUSTOMRC_SILENT_OUTPUT" != true ]]; then
          echo -e "${RED}${CROSS}${NC} ${WHITE}Ignored:${NC} ${BLUE}$fileName ${MAGENTA}[$OS_NAME]${NC}"
        fi
      fi
    done
  fi
else
  echo -e "${CROSS}${YELLOW}Unsupported OS ${BLUE}$OS_NAME${YELLOW}, skipping OS-specific rc files${NC}"
fi

# Source the combined file if it has content
if [[ -s "$TEMP_COMBINED_RC" ]]; then
  if [[ "$CUSTOMRC_SILENT_OUTPUT" != true ]]; then
    echo -e "${CYAN}${INFO}${NC} ${CYAN}Sourcing combined configuration...${NC}"
  fi

  source_start_time=$(date +%s%N)
  source "$TEMP_COMBINED_RC"
  source_duration=$(get_duration_ms $source_start_time)
fi

# Calculate total duration and display summary
CUSTOMRC_TOTAL_DURATION=$(get_duration_ms $CUSTOMRC_START_TIME)

if [[ "$CUSTOMRC_SILENT_OUTPUT" != true ]]; then
  print_divider "$PURPLE" "customrc"
  echo -e "${CYAN}${INFO}${NC} ${WHITE}Initialization complete${NC}"
  echo -e "    ${GREEN}${CHECK}${NC} ${WHITE}Loaded: ${GREEN}${CUSTOMRC_LOADED_COUNT}${NC}"
  echo -e "    ${RED}${CROSS}${NC} ${WHITE}Ignored: ${RED}${CUSTOMRC_IGNORED_COUNT}${NC}"
  echo -e "    ${YELLOW}${WARN}${NC} ${WHITE}Duration: ${YELLOW}${CUSTOMRC_TOTAL_DURATION}ms${NC}"
  echo ""
fi

# Apply prompt fix if needed
if [[ -f "$CURRENT_PATH/fix-prompt-at-bottom.sh" && "$TERM_PROGRAM" != "WarpTerminal" ]]; then
  source "$CURRENT_PATH/fix-prompt-at-bottom.sh"
fi

# Clean up variables to prevent pollution
unset RED GREEN YELLOW BLUE PURPLE CYAN WHITE BOLD NC
unset CHECK CROSS WARN INFO ROCKET
unset print_divider is_ignored add_file_to_combined get_duration_ms
unset fileName file attempt
