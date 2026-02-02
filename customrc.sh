#!/bin/bash

# Colors
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color

# Symbols
CHECKMARK='\xE2\x9C\x94'
ROCKET='\xF0\x9F\x9A\x80'
CROSSMARK='\xE2\x9C\x98'
WAIT='\xE2\x8C\x9B'
WARNING='\xE2\x9A\xA0'

CURRENT_PATH=$(dirname "$0")

CUSTOMRC_SILENT_OUTPUT=true

# Initialize timing and counters
CUSTOMRC_START_TIME=$(date +%s%N)
CUSTOMRC_LOADED_COUNT=0
CUSTOMRC_IGNORED_COUNT=0
CUSTOMRC_SLOW_THRESHOLD_MS=100

if [[ "$CUSTOMRC_SILENT_OUTPUT" != true ]]; then
  echo -e "${ROCKET} Customrc initializing..."
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
    # $fileName, $category -> expanded NOW (by customrc.sh)
    # \$_file_start_time, \$CUSTOMRC_SILENT_OUTPUT -> literal in file (expanded LATER by generated script)
    cat <<EOF >> "$TEMP_COMBINED_RC"
_file_duration=\$(get_duration_ms \$_file_start_time)
if [[ "\$CUSTOMRC_SILENT_OUTPUT" != true ]]; then
  echo -e "  \${GREEN}\${CHECKMARK}\${NC} loaded:  \${BLUE}$fileName \${MAGENTA}[$category]\${NC} (\${YELLOW}\${_file_duration}ms\${NC})"
fi
EOF

    echo "# === End of $fileName [$category] ===" >> "$TEMP_COMBINED_RC"
    echo "" >> "$TEMP_COMBINED_RC"
    ((CUSTOMRC_LOADED_COUNT++))
    
    if [[ "$CUSTOMRC_SILENT_OUTPUT" != true ]]; then
      echo -e "  ${GREEN}${CHECKMARK}${NC} queued:  ${BLUE}$fileName ${MAGENTA}[$category]${NC}"
    fi
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
        echo -e "  ${RED}${CROSSMARK}${NC} ignored: ${BLUE}$fileName ${MAGENTA}[global]${NC}"
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
          echo -e "  ${RED}${CROSSMARK}${NC} ignored: ${BLUE}$fileName ${MAGENTA}[$OS_NAME]${NC}"
        fi
      fi
    done
  fi
else
  echo -e "${CROSSMARK}${YELLOW}unsupported OS ${BLUE}$OS_NAME${YELLOW}, skipping OS-specific rc files${NC}"
fi

# Source the combined file if it has content
if [[ -s "$TEMP_COMBINED_RC" ]]; then
  if [[ "$CUSTOMRC_SILENT_OUTPUT" != true ]]; then
    echo -e "${WAIT} Sourcing combined configuration..."
  fi
  
  source_start_time=$(date +%s%N)
  source "$TEMP_COMBINED_RC"
  source_duration=$(get_duration_ms $source_start_time)
  
  # if [[ "$CUSTOMRC_SILENT_OUTPUT" != true ]]; then
  #   if [[ $source_duration -gt $CUSTOMRC_SLOW_THRESHOLD_MS ]]; then
  #     echo -e "${GREEN}${CHECKMARK}${NC} sourced: ${GREEN}combined configuration${NC} (${YELLOW}${source_duration}ms${NC})"
  #   else
  #     echo -e "${GREEN}${CHECKMARK}${NC} sourced: ${GREEN}combined configuration${NC} (${source_duration}ms)"
  #   fi
  # fi
fi

# Calculate total duration and display summary
CUSTOMRC_TOTAL_DURATION=$(get_duration_ms $CUSTOMRC_START_TIME)

if [[ "$CUSTOMRC_SILENT_OUTPUT" != true ]]; then
  echo -e "${ROCKET} Initialization complete: ${GREEN}${CUSTOMRC_LOADED_COUNT} loaded${NC}, ${RED}${CUSTOMRC_IGNORED_COUNT} ignored${NC}, took ${CUSTOMRC_TOTAL_DURATION}ms"
fi

# Apply prompt fix if needed
if [[ -f "$CURRENT_PATH/fix-prompt-at-bottom.sh" && "$TERM_PROGRAM" != "WarpTerminal" ]]; then
  source "$CURRENT_PATH/fix-prompt-at-bottom.sh"
fi

# Clean up variables
fileName=
file=
