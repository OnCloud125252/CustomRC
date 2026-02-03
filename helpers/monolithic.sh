# Monolithic cache helper for production mode
# Generates and manages a cached monolithic RC file for fast startup

CUSTOMRC_MONOLITHIC_CACHE="${CUSTOMRC_CACHE_DIR:-$HOME/.cache/customrc}/monolithic.sh"

# Checks if any source file is newer than the cached monolithic file
_monolithic_needs_rebuild() {
  local cache_file="$1"

  # If cache doesn't exist, rebuild needed
  [[ ! -f "$cache_file" ]] && return 0

  local cache_mtime
  cache_mtime=$(stat -f %m "$cache_file" 2>/dev/null || stat -c %Y "$cache_file" 2>/dev/null)

  # Check configs.sh
  local config_mtime
  config_mtime=$(stat -f %m "$CURRENT_PATH/configs.sh" 2>/dev/null || stat -c %Y "$CURRENT_PATH/configs.sh" 2>/dev/null)
  [[ "$config_mtime" -gt "$cache_mtime" ]] && return 0

  # Check all module directories
  local dir file file_mtime
  for dir in "$CUSTOMRC_RC_MODULES_PATH/Global" "$CUSTOMRC_RC_MODULES_PATH/Darwin" "$CUSTOMRC_RC_MODULES_PATH/Linux"; do
    [[ ! -d "$dir" ]] && continue
    for file in "$dir"/*; do
      [[ ! -f "$file" ]] && continue
      file_mtime=$(stat -f %m "$file" 2>/dev/null || stat -c %Y "$file" 2>/dev/null)
      [[ "$file_mtime" -gt "$cache_mtime" ]] && return 0
    done
  done

  return 1
}

# Appends modules from a directory to the monolithic file, respecting ignore lists
_append_modules_from_dir() {
  local directory="$1" category="$2" cache_file="$3"
  shift 3
  local ignore_list=("$@")

  [[ ! -d "$directory" ]] && return

  local filepath filename is_ignored_file
  for filepath in "$directory"/*; do
    [[ ! -f "$filepath" ]] && continue
    filename="${filepath##*/}"

    # Check if file is in ignore list
    is_ignored_file=false
    for ignored in "${ignore_list[@]}"; do
      [[ "$ignored" == "$filename" ]] && { is_ignored_file=true; break; }
    done

    if [[ "$is_ignored_file" == false ]]; then
      {
        echo "# === $filename [$category] ==="
        cat "$filepath"
        echo ""
      } >> "$cache_file"
    fi
  done
}

# Generates a clean monolithic file without timing instrumentation
generate_monolithic_file() {
  local cache_file="$1"
  local cache_dir="${cache_file%/*}"

  # Ensure cache directory exists
  [[ ! -d "$cache_dir" ]] && mkdir -p "$cache_dir"

  # Create fresh cache file with header
  echo "# Monolithic RC - Generated $(date '+%Y-%m-%d %H:%M:%S')" > "$cache_file"
  echo "# Do not edit - regenerated automatically when source files change" >> "$cache_file"
  echo "" >> "$cache_file"

  # Append Global modules
  _append_modules_from_dir \
    "$CUSTOMRC_RC_MODULES_PATH/Global" \
    "Global" \
    "$cache_file" \
    "${CUSTOMRC_GLOBAL_IGNORE_LIST[@]}"

  # Append OS-specific modules
  local os_name
  os_name=$(uname)
  case "$os_name" in
    Darwin)
      _append_modules_from_dir \
        "$CUSTOMRC_RC_MODULES_PATH/Darwin" \
        "Darwin" \
        "$cache_file" \
        "${CUSTOMRC_DARWIN_IGNORE_LIST[@]}"
      ;;
    Linux)
      _append_modules_from_dir \
        "$CUSTOMRC_RC_MODULES_PATH/Linux" \
        "Linux" \
        "$cache_file" \
        "${CUSTOMRC_LINUX_IGNORE_LIST[@]}"
      ;;
  esac
}
