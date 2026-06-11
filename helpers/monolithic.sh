# Monolithic cache helper for production mode
# Generates and manages a cached monolithic RC file for fast startup

CUSTOMRC_MONOLITHIC_CACHE="${CUSTOMRC_CACHE_DIR:-$HOME/.cache/customrc}/monolithic.sh"

# Checks if any source file is newer than the cached monolithic file.
# Uses shell built-in `-nt` (no subprocess) for single-file checks and a single
# `find -newer ... -print -quit` per directory (one subprocess, exits at first
# match). Replaces an earlier implementation that forked `stat` per file.
_monolithic_needs_rebuild() {
  local cache_file="$1"

  # If cache doesn't exist, rebuild needed
  [[ ! -f "$cache_file" ]] && return 0

  # Check configs.sh and version (built-in mtime test, no subprocess)
  [[ -f "$CURRENT_PATH/configs.sh" && "$CURRENT_PATH/configs.sh" -nt "$cache_file" ]] && return 0
  [[ -f "$CURRENT_PATH/version"    && "$CURRENT_PATH/version"    -nt "$cache_file" ]] && return 0

  # Check module directories: pure-builtin glob + `-nt` test, no subprocess.
  # (N.) = nullglob (empty dir won't trip nomatch) + regular files only.
  # Bails at the first file newer than the cache. Replaces a `find` fork per
  # directory; ~74 builtin mtime tests are far cheaper than 3 subprocesses.
  local dir f
  for dir in "$CUSTOMRC_RC_MODULES_PATH/Global" "$CUSTOMRC_RC_MODULES_PATH/Darwin" "$CUSTOMRC_RC_MODULES_PATH/Linux"; do
    [[ ! -d "$dir" ]] && continue
    for f in "$dir"/*.sh(N.); do
      [[ "$f" -nt "$cache_file" ]] && return 0
    done
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

  # Compile to .zwc so subsequent shells load the cached AST instead of reparsing.
  # zsh's `source` auto-prefers the .zwc when newer than the source file.
  # Errors here are non-fatal: a missing .zwc just means slightly slower parse.
  zcompile -R -- "${cache_file}.zwc" "$cache_file" 2>/dev/null

  return 0
}
