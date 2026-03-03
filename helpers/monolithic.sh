# Monolithic cache helper for production mode
# Generates and manages a cached monolithic RC file for fast startup

CUSTOMRC_MONOLITHIC_CACHE="${CUSTOMRC_CACHE_DIR:-$HOME/.cache/customrc}/monolithic.sh"

# Get file mtime in a cross-platform way
# Usage: _get_mtime <file_path>
# Sets: _MTIME_RESULT variable with the mtime (or 0 on error)
_get_mtime() {
  local file_path="$1"
  _MTIME_RESULT=0

  if [[ "$(uname)" == "Darwin" ]]; then
    _MTIME_RESULT=$(stat -f %m "$file_path" 2>/dev/null) || _MTIME_RESULT=0
  else
    _MTIME_RESULT=$(stat -c %Y "$file_path" 2>/dev/null) || _MTIME_RESULT=0
  fi

  [[ -z "$_MTIME_RESULT" ]] && _MTIME_RESULT=0
}

# Checks if any source file is newer than the cached monolithic file
_monolithic_needs_rebuild() {
  local cache_file="$1"

  # If cache doesn't exist, rebuild needed
  [[ ! -f "$cache_file" ]] && return 0

  local cache_mtime
  _get_mtime "$cache_file"
  cache_mtime="$_MTIME_RESULT"

  # Check configs.sh
  local config_mtime
  if [[ -f "$CURRENT_PATH/configs.sh" ]]; then
    _get_mtime "$CURRENT_PATH/configs.sh"
    config_mtime="$_MTIME_RESULT"
    [[ "$config_mtime" -gt "$cache_mtime" ]] && return 0
  fi

  # Check version file
  local version_mtime
  if [[ -f "$CURRENT_PATH/version" ]]; then
    _get_mtime "$CURRENT_PATH/version"
    version_mtime="$_MTIME_RESULT"
    [[ "$version_mtime" -gt "$cache_mtime" ]] && return 0
  fi

  # Check all module directories
  local dir file file_mtime
  for dir in "$CUSTOMRC_RC_MODULES_PATH/Global" "$CUSTOMRC_RC_MODULES_PATH/Darwin" "$CUSTOMRC_RC_MODULES_PATH/Linux"; do
    [[ ! -d "$dir" ]] && continue
    while IFS= read -r file; do
      [[ ! -f "$file" ]] && continue
      _get_mtime "$file"
      file_mtime="$_MTIME_RESULT"
      [[ "$file_mtime" -gt "$cache_mtime" ]] && return 0
    done < <(find "$dir" -maxdepth 1 -name "*.sh" -type f 2>/dev/null)
  done

  return 1
}

# Outputs modules from a directory to stdout, respecting ignore lists
# Usage: _append_modules_from_dir <directory> <category> <ignore_list...>
_append_modules_from_dir() {
  local directory="$1" category="$2"
  shift 2
  local ignore_list=("$@")

  [[ ! -d "$directory" ]] && return 0

  local filepath filename is_ignored_file
  while IFS= read -r filepath; do
    [[ ! -f "$filepath" ]] && continue
    filename="${filepath##*/}"

    # Check if file is in ignore list
    is_ignored_file=false
    for ignored in "${ignore_list[@]}"; do
      [[ "$ignored" == "$filename" ]] && { is_ignored_file=true; break; }
    done

    if [[ "$is_ignored_file" == false ]]; then
      echo "# === $filename [$category] ==="
      command cat "$filepath"
      echo ""
    fi
  done < <(find "$directory" -maxdepth 1 -name "*.sh" -type f 2>/dev/null | sort)
}

# Generates a clean monolithic file without timing instrumentation
# Returns: 0 on success, 1 on failure
generate_monolithic_file() {
  local cache_file="$1"
  local cache_dir="${cache_file%/*}"

  # Check if cache directory parent is writable (if it exists)
  if [[ -d "$cache_dir" && ! -w "$cache_dir" ]]; then
    echo "Error: Cache directory not writable: $cache_dir" >&2
    return 1
  fi

  # Ensure cache directory exists
  if [[ ! -d "$cache_dir" ]]; then
    if ! command mkdir -p "$cache_dir" 2>/dev/null; then
      echo "Error: Failed to create cache directory: $cache_dir" >&2
      return 1
    fi
  fi

  # Create fresh cache file with header
  if ! {
    echo "# Monolithic RC - Generated $(date '+%Y-%m-%d %H:%M:%S')"
    echo "# Do not edit - regenerated automatically when source files change"
    echo ""

    # Append Global modules
    _append_modules_from_dir \
      "$CUSTOMRC_RC_MODULES_PATH/Global" \
      "Global" \
      "/dev/stdout" \
      "${CUSTOMRC_GLOBAL_IGNORE_LIST[@]}"

    # Append OS-specific modules
    local os_name
    os_name=$(uname)
    case "$os_name" in
      Darwin)
        _append_modules_from_dir \
          "$CUSTOMRC_RC_MODULES_PATH/Darwin" \
          "Darwin" \
          "/dev/stdout" \
          "${CUSTOMRC_DARWIN_IGNORE_LIST[@]}"
        ;;
      Linux)
        _append_modules_from_dir \
          "$CUSTOMRC_RC_MODULES_PATH/Linux" \
          "Linux" \
          "/dev/stdout" \
          "${CUSTOMRC_LINUX_IGNORE_LIST[@]}"
        ;;
    esac
  } > "$cache_file"; then
    echo "Error: Failed to generate monolithic cache file" >&2
    return 1
  fi

  # Verify file was created and has content
  if [[ ! -f "$cache_file" ]]; then
    echo "Error: Cache file was not created: $cache_file" >&2
    return 1
  fi

  if [[ ! -s "$cache_file" ]]; then
    echo "Error: Cache file was created but is empty: $cache_file" >&2
    return 1
  fi

  return 0
}
