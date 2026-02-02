# Checks if a filename is in the provided ignore list
is_ignored() {
  local filename="$1" ignored_item; shift
  for ignored_item in "$@"; do
    [[ "$ignored_item" == "$filename" ]] && return 0
  done
  return 1
}

# Appends a file's content to the combined script with timing instrumentation
add_file_to_combined() {
  local filepath="$1" filename="$2" category="$3"
  [[ ! -f "$filepath" ]] && return

  {
    echo "# === Start of $filename [$category] ==="
    echo "_file_start_time=\$(date +%s%N)"
    cat "$filepath"
    echo ""
    echo "_file_duration=\$(get_duration_ms \$_file_start_time)"
    echo "if [[ \"\$CUSTOMRC_SILENT_OUTPUT\" != true ]]; then"
    echo "  _duration_color=\$(get_duration_color \$_file_duration)"
    echo "  echo -e \"${CHECK} ${WHITE}Loaded:${NC} ${BLUE}$filename ${PURPLE}[$category]${NC} (\${_duration_color}\${_file_duration}ms${NC})\""
    echo "fi"
    echo "# === End of $filename [$category] ==="
    echo ""
  } >> "$TEMP_COMBINED_RC"

  ((CUSTOMRC_LOADED_COUNT++))
}

# Processes all RC files in a directory, respecting the ignore list
process_rc_directory() {
  local directory="$1" category="$2" filepath filename
  shift 2

  [[ ! -d "$directory" ]] && return

  for filepath in "$directory"/*; do
    filename="${filepath##*/}"
    if is_ignored "$filename" "$@"; then
      ((CUSTOMRC_IGNORED_COUNT++))
      log_message "${CROSS} ${WHITE}Ignored:${NC} ${BLUE}$filename ${PURPLE}[$category]${NC}"
    else
      add_file_to_combined "$filepath" "$filename" "$category"
    fi
  done
}
