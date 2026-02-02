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
