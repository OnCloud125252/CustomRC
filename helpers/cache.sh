# Cache helper for CustomRC
# Provides centralized caching with binary version checking, TTL support, and management utilities

CUSTOMRC_CACHE_DIR="${CUSTOMRC_CACHE_DIR:-$HOME/.cache/customrc}"
CUSTOMRC_CACHE_META_DIR="$CUSTOMRC_CACHE_DIR/.meta"

# Convert TTL string to seconds (e.g., "1h" -> 3600, "7d" -> 604800)
# Usage: _cache_ttl_to_seconds "7d" result_var
_cache_ttl_to_seconds() {
  local ttl="$1" result_var="$2"
  local value="${ttl%[smhdw]}"
  local unit="${ttl: -1}"

  case "$unit" in
    s) printf -v "$result_var" '%d' "$value" ;;
    m) printf -v "$result_var" '%d' "$((value * 60))" ;;
    h) printf -v "$result_var" '%d' "$((value * 3600))" ;;
    d) printf -v "$result_var" '%d' "$((value * 86400))" ;;
    w) printf -v "$result_var" '%d' "$((value * 604800))" ;;
    *) printf -v "$result_var" '%d' "$ttl" ;;  # Assume seconds if no unit
  esac
}

# Check if cache has exceeded TTL
# Usage: _cache_is_expired <cache_file> <ttl_seconds>
# Returns: 0 if expired, 1 if still valid
_cache_is_expired() {
  local cache_file="$1" ttl_seconds="$2"
  [[ -z "$ttl_seconds" || "$ttl_seconds" -eq 0 ]] && return 1

  local file_age=$(( $(date +%s) - $(stat -f %m "$cache_file" 2>/dev/null || echo 0) ))
  [[ "$file_age" -gt "$ttl_seconds" ]]
}

# Check if binary is newer than cache file
# Usage: _cache_binary_newer <binary_path> <cache_file>
# Returns: 0 if binary is newer, 1 otherwise
_cache_binary_newer() {
  local binary="$1" cache_file="$2"
  [[ -z "$binary" || ! -f "$binary" ]] && return 1
  [[ "$binary" -nt "$cache_file" ]]
}

# Write metadata for a cache entry
# Usage: _cache_write_meta <name> <key> <value>
_cache_write_meta() {
  local name="$1" key="$2" value="$3"
  local meta_file="$CUSTOMRC_CACHE_META_DIR/${name}.meta"

  mkdir -p "$CUSTOMRC_CACHE_META_DIR"

  # Simple key=value format
  if [[ -f "$meta_file" ]]; then
    # Remove existing key if present
    grep -v "^${key}=" "$meta_file" > "${meta_file}.tmp" 2>/dev/null || true
    mv "${meta_file}.tmp" "$meta_file"
  fi
  echo "${key}=${value}" >> "$meta_file"
}

# Read metadata value for a cache entry
# Usage: _cache_read_meta <name> <key> [result_var]
_cache_read_meta() {
  local name="$1" key="$2" result_var="${3:-}"
  local meta_file="$CUSTOMRC_CACHE_META_DIR/${name}.meta"
  local value=""

  if [[ -f "$meta_file" ]]; then
    value=$(grep "^${key}=" "$meta_file" 2>/dev/null | cut -d= -f2-)
  fi

  if [[ -n "$result_var" ]]; then
    printf -v "$result_var" '%s' "$value"
  else
    echo "$value"
  fi
}

# Main caching function
# Usage: cache_init <name> <command> [options]
# Options:
#   --ttl <duration>       Cache TTL (e.g., "1h", "7d", "3600")
#   --check-binary <path>  Regenerate if binary is newer than cache
#   --extension <ext>      File extension (default: zsh)
#   --no-source            Don't source the cache file (for non-shell content)
# Returns: 0 on success, 1 on failure
cache_init() {
  local name="$1" command="$2"
  shift 2

  local ttl="" check_binary="" extension="zsh" no_source=false

  # Parse options
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --ttl) ttl="$2"; shift 2 ;;
      --check-binary) check_binary="$2"; shift 2 ;;
      --extension) extension="$2"; shift 2 ;;
      --no-source) no_source=true; shift ;;
      *) shift ;;
    esac
  done

  local cache_file="$CUSTOMRC_CACHE_DIR/${name}.${extension}"
  local needs_regenerate=false

  mkdir -p "$CUSTOMRC_CACHE_DIR"

  # Check if cache needs regeneration
  if [[ ! -f "$cache_file" ]]; then
    needs_regenerate=true
  elif [[ -n "$check_binary" ]] && _cache_binary_newer "$check_binary" "$cache_file"; then
    needs_regenerate=true
  elif [[ -n "$ttl" ]]; then
    local ttl_seconds
    _cache_ttl_to_seconds "$ttl" ttl_seconds
    if _cache_is_expired "$cache_file" "$ttl_seconds"; then
      needs_regenerate=true
    fi
  fi

  # Regenerate cache if needed
  if [[ "$needs_regenerate" == true ]]; then
    local temp_file="${cache_file}.tmp"
    if eval "$command" > "$temp_file" 2>/dev/null; then
      mv "$temp_file" "$cache_file"
      _cache_write_meta "$name" "command" "$command"
      _cache_write_meta "$name" "created" "$(date +%s)"
      [[ -n "$check_binary" ]] && _cache_write_meta "$name" "binary" "$check_binary"
      [[ -n "$ttl" ]] && _cache_write_meta "$name" "ttl" "$ttl"
    else
      rm -f "$temp_file"
      # Keep stale cache if regeneration fails
      [[ ! -f "$cache_file" ]] && return 1
    fi
  fi

  # Source the cache unless --no-source is set
  if [[ "$no_source" == false && -f "$cache_file" ]]; then
    source "$cache_file"
  fi

  return 0
}

# Read cached value into a variable (for non-sourced caches)
# Usage: cache_get <name> [result_var] [--extension ext]
# Returns: 0 if cache exists and has content, 1 otherwise
cache_get() {
  local name="$1" result_var="${2:-}" extension="zsh"
  shift
  [[ $# -gt 0 ]] && shift

  # Parse options
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --extension) extension="$2"; shift 2 ;;
      *) shift ;;
    esac
  done

  local cache_file="$CUSTOMRC_CACHE_DIR/${name}.${extension}"

  [[ ! -s "$cache_file" ]] && return 1

  if [[ -n "$result_var" ]]; then
    printf -v "$result_var" '%s' "$(<"$cache_file")"
  else
    cat "$cache_file"
  fi

  return 0
}

# List all caches with status
# Usage: cache_list
cache_list() {
  local cache_file name extension created ttl binary age status

  if [[ ! -d "$CUSTOMRC_CACHE_DIR" ]]; then
    echo "No caches found"
    return 0
  fi

  printf "%-15s %-10s %-12s %-20s %s\n" "NAME" "SIZE" "AGE" "STATUS" "BINARY"
  printf "%-15s %-10s %-12s %-20s %s\n" "----" "----" "---" "------" "------"

  for cache_file in "$CUSTOMRC_CACHE_DIR"/*; do
    [[ -f "$cache_file" ]] || continue
    [[ "$cache_file" == *.meta ]] && continue
    [[ -d "$cache_file" ]] && continue

    local basename=$(basename "$cache_file")
    name="${basename%.*}"
    extension="${basename##*.}"

    local size=$(stat -f %z "$cache_file" 2>/dev/null || echo 0)
    local size_human
    if [[ "$size" -gt 1048576 ]]; then
      size_human="$((size / 1048576))MB"
    elif [[ "$size" -gt 1024 ]]; then
      size_human="$((size / 1024))KB"
    else
      size_human="${size}B"
    fi

    local file_time=$(stat -f %m "$cache_file" 2>/dev/null || echo 0)
    local now=$(date +%s)
    age=$((now - file_time))
    local age_human
    if [[ "$age" -gt 86400 ]]; then
      age_human="$((age / 86400))d ago"
    elif [[ "$age" -gt 3600 ]]; then
      age_human="$((age / 3600))h ago"
    elif [[ "$age" -gt 60 ]]; then
      age_human="$((age / 60))m ago"
    else
      age_human="${age}s ago"
    fi

    status="valid"
    ttl=$(_cache_read_meta "$name" "ttl")
    if [[ -n "$ttl" ]]; then
      local ttl_seconds
      _cache_ttl_to_seconds "$ttl" ttl_seconds
      if _cache_is_expired "$cache_file" "$ttl_seconds"; then
        status="expired (ttl: $ttl)"
      fi
    fi

    binary=$(_cache_read_meta "$name" "binary")
    if [[ -n "$binary" ]] && _cache_binary_newer "$binary" "$cache_file"; then
      status="stale (binary updated)"
    fi

    local binary_short=""
    [[ -n "$binary" ]] && binary_short=$(basename "$binary")

    printf "%-15s %-10s %-12s %-20s %s\n" "$name" "$size_human" "$age_human" "$status" "$binary_short"
  done
}

# Clear specific or all caches
# Usage: cache_clear [name]
cache_clear() {
  local name="${1:-}"

  if [[ -n "$name" ]]; then
    rm -f "$CUSTOMRC_CACHE_DIR/${name}".* 2>/dev/null
    rm -f "$CUSTOMRC_CACHE_META_DIR/${name}.meta" 2>/dev/null
    echo "Cleared cache: $name"
  else
    rm -rf "$CUSTOMRC_CACHE_DIR"
    echo "Cleared all caches"
  fi
}

# Force regenerate cache
# Usage: cache_refresh [name]
cache_refresh() {
  local name="${1:-}"

  if [[ -z "$name" ]]; then
    echo "Usage: cache_refresh <name>"
    return 1
  fi

  local command=$(_cache_read_meta "$name" "command")
  local binary=$(_cache_read_meta "$name" "binary")
  local ttl=$(_cache_read_meta "$name" "ttl")

  if [[ -z "$command" ]]; then
    echo "No command found for cache: $name"
    return 1
  fi

  # Remove existing cache to force regeneration
  rm -f "$CUSTOMRC_CACHE_DIR/${name}".* 2>/dev/null

  # Rebuild args
  local args=""
  [[ -n "$binary" ]] && args="$args --check-binary $binary"
  [[ -n "$ttl" ]] && args="$args --ttl $ttl"

  echo "Refreshing cache: $name"
  eval "cache_init '$name' '$command' $args"
}
