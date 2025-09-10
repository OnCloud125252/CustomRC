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
HOURGLASS='\xE2\x8C\x9B'
WARNING='\xE2\x9A\xA0'

CURRENT_PATH=$(dirname "$0")

CUSTOMRC_SILENT_OUTPUT=false

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

CUSTOMRC_GLOBAL_RC_PATH="$CUSTOMRC_PATH/Global"
for file in $CUSTOMRC_GLOBAL_RC_PATH/*; do
  fileName=$(basename "$file")
  if ! is_ignored $fileName $CUSTOMRC_GLOBAL_IGNORE_LIST; then
    if [[ -f $file ]]; then
      file_start_time=$(date +%s%N)
      source "$file"
      ((CUSTOMRC_LOADED_COUNT++))
      if [[ "$CUSTOMRC_SILENT_OUTPUT" != true ]]; then
        duration_ms=$(get_duration_ms $file_start_time)
        if [[ $duration_ms -gt $CUSTOMRC_SLOW_THRESHOLD_MS ]]; then
          echo -e "  ${YELLOW}${CHECKMARK}${NC} loaded:  ${BLUE}$fileName ${MAGENTA}[global]${NC} (${YELLOW}${duration_ms}ms${NC})"
        else
          echo -e "  ${GREEN}${CHECKMARK}${NC} loaded:  ${BLUE}$fileName ${MAGENTA}[global]${NC} (${duration_ms}ms)"
        fi
      fi
    fi
  else
    ((CUSTOMRC_IGNORED_COUNT++))
    if [[ "$CUSTOMRC_SILENT_OUTPUT" != true ]]; then
      echo -e "  ${RED}${CROSSMARK}${NC} ignored: ${BLUE}$fileName ${MAGENTA}[global]${NC}"
    fi
  fi
done

OS_NAME=$(uname)
if [[ $OS_NAME == "Darwin" || $OS_NAME == "Linux" ]]; then
  if [[ $OS_NAME == "Darwin" ]]; then
    CUSTOMRC_OS_IGNORE_LIST=("${CUSTOMRC_Darwin_IGNORE_LIST[@]}")
  elif [[ $OS_NAME == "Linux" ]]; then
    CUSTOMRC_OS_IGNORE_LIST=("${CUSTOMRC_Linux_IGNORE_LIST[@]}")
  fi

  CUSTOMRC_RC_PATH="$CUSTOMRC_PATH/$OS_NAME"
  for file in $CUSTOMRC_RC_PATH/*; do
    fileName=$(basename "$file")
    if ! is_ignored $fileName $CUSTOMRC_OS_IGNORE_LIST; then
      if [[ -f $file ]]; then
        file_start_time=$(date +%s%N)
        source "$file"
        ((CUSTOMRC_LOADED_COUNT++))
        if [[ "$CUSTOMRC_SILENT_OUTPUT" != true ]]; then
          duration_ms=$(get_duration_ms $file_start_time)
          if [[ $duration_ms -gt $CUSTOMRC_SLOW_THRESHOLD_MS ]]; then
            echo -e "  ${GREEN}${CHECKMARK}${NC} loaded:  ${BLUE}$fileName ${MAGENTA}[$OS_NAME]${NC} (${YELLOW}${duration_ms}ms${NC})"
          else
            echo -e "  ${GREEN}${CHECKMARK}${NC} loaded:  ${BLUE}$fileName ${MAGENTA}[$OS_NAME]${NC} (${duration_ms}ms)"
          fi
        fi
      fi
    else
      ((CUSTOMRC_IGNORED_COUNT++))
      if [[ "$CUSTOMRC_SILENT_OUTPUT" != true ]]; then
        echo -e "  ${RED}${CROSSMARK}${NC} ignored: ${BLUE}$fileName ${MAGENTA}[$OS_NAME]${NC}"
      fi
    fi
  done
else
  echo -e "${CROSSMARK}${YELLOW}unsupported OS ${BLUE}$OS_NAME${YELLOW}, skipping OS-specific rc files${NC}"
fi

# Calculate total duration and display summary
CUSTOMRC_TOTAL_DURATION=$(get_duration_ms $CUSTOMRC_START_TIME)

if [[ "$CUSTOMRC_SILENT_OUTPUT" != true ]]; then
  echo -e "${HOURGLASS} Initialization complete: ${GREEN}${CUSTOMRC_LOADED_COUNT} loaded${NC}, ${RED}${CUSTOMRC_IGNORED_COUNT} ignored${NC}, took ${CUSTOMRC_TOTAL_DURATION}ms"
fi


if [[ -f "$CURRENT_PATH/fix-prompt-at-bottom.sh" && "$TERM_PROGRAM" != "WarpTerminal" ]]; then
  source "$CURRENT_PATH/fix-prompt-at-bottom.sh"
fi

fileName=
file=
