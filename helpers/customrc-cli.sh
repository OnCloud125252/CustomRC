# CustomRC CLI
# Provides git-style subcommands for managing the CustomRC shell configuration system
#
# Usage: customrc <command> [subcommand] [options]

# ─────────────────────────────────────────────────────────────────────────────
# Styles & Logging
# ─────────────────────────────────────────────────────────────────────────────

# CLI Colors (prefixed to avoid collision with debug mode cleanup)
_CLI_RED='\033[0;31m'
_CLI_GREEN='\033[0;32m'
_CLI_YELLOW='\033[0;33m'
_CLI_BLUE='\033[0;34m'
_CLI_PURPLE='\033[0;35m'
_CLI_CYAN='\033[0;36m'
_CLI_WHITE='\033[0;37m'
_CLI_NC='\033[0m' # No Color

# CLI Symbols (prefixed to avoid collision with debug mode cleanup)
_CLI_CHECK='\033[0;32m[✓]\033[0m'
_CLI_CROSS='\033[0;31m[✗]\033[0m'
_CLI_WARN='\033[0;33m[!]\033[0m'
_CLI_INFO='\033[0;36m[i]\033[0m'

# Prints a full-width divider line with a centered label
_customrc_divider() {
  local color="${1:-$_CLI_PURPLE}" label="${2:-customrc}"
  local terminal_width=${CUSTOMRC_TERMINAL_WIDTH:-80}
  local padding_width=$((terminal_width - ${#label} - 6))
  local spaces
  printf -v spaces '%*s' "$padding_width" ''
  printf '%b━━━━[%s]%s%b\n' "$color" "$label" "${spaces// /━}" "$_CLI_NC"
}

_customrc_info() {
  echo -e "$_CLI_INFO $1"
}

_customrc_success() {
  echo -e "$_CLI_CHECK $1"
}

_customrc_warn() {
  echo -e "$_CLI_WARN $1"
}

_customrc_error() {
  echo -e "$_CLI_CROSS $1"
}

# ─────────────────────────────────────────────────────────────────────────────
# Path Helpers
# ─────────────────────────────────────────────────────────────────────────────

_customrc_get_path() {
  echo "${CUSTOMRC_PATH:-$HOME/.customrc}"
}

_customrc_get_modules_path() {
  echo "$(_customrc_get_path)/rc-modules"
}

_customrc_get_helpers_path() {
  echo "$(_customrc_get_path)/helpers"
}

_customrc_get_cache_path() {
  echo "${CUSTOMRC_CACHE_DIR:-$HOME/.cache/customrc}"
}

# ─────────────────────────────────────────────────────────────────────────────
# Sync Commands
# ─────────────────────────────────────────────────────────────────────────────

_customrc_sync_init() {
  local modules_path="$(_customrc_get_modules_path)"
  local url="${1:-}"

  if [[ -n "$url" ]]; then
    # Clone from URL
    if [[ -d "$modules_path" ]]; then
      local backup_path="${modules_path}.backup.$(date +%Y%m%d_%H%M%S)"
      _customrc_info "Backing up existing rc-modules to $backup_path"
      mv "$modules_path" "$backup_path"
    fi
    _customrc_info "Cloning from $url..."
    if git clone "$url" "$modules_path"; then
      _customrc_success "Cloned rc-modules from $url"
    else
      _customrc_error "Failed to clone from $url"
      return 1
    fi
  else
    # Initialize as git repo
    if [[ ! -d "$modules_path" ]]; then
      _customrc_error "rc-modules directory not found: $modules_path"
      return 1
    fi
    if [[ -d "$modules_path/.git" ]]; then
      _customrc_warn "rc-modules is already a git repository"
      return 0
    fi
    _customrc_info "Initializing git repository in rc-modules..."
    if (cd "$modules_path" && git init); then
      _customrc_success "Initialized git repository in rc-modules"
    else
      _customrc_error "Failed to initialize git repository"
      return 1
    fi
  fi
}

_customrc_sync_push() {
  local modules_path="$(_customrc_get_modules_path)"

  if [[ ! -d "$modules_path/.git" ]]; then
    _customrc_error "rc-modules is not a git repository. Run 'customrc sync init' first."
    return 1
  fi

  _customrc_info "Pushing rc-modules..."
  if (cd "$modules_path" && git push); then
    _customrc_success "Pushed rc-modules to remote"
  else
    _customrc_error "Failed to push. Check if remote is configured."
    return 1
  fi
}

_customrc_sync_pull() {
  local modules_path="$(_customrc_get_modules_path)"

  if [[ ! -d "$modules_path/.git" ]]; then
    _customrc_error "rc-modules is not a git repository. Run 'customrc sync init' first."
    return 1
  fi

  _customrc_info "Pulling rc-modules..."
  if (cd "$modules_path" && git pull); then
    _customrc_success "Pulled latest rc-modules from remote"
  else
    _customrc_error "Failed to pull. Check your network connection."
    return 1
  fi
}

_customrc_sync_status() {
  local modules_path="$(_customrc_get_modules_path)"

  if [[ ! -d "$modules_path/.git" ]]; then
    _customrc_warn "rc-modules is not a git repository"
    _customrc_info "Run 'customrc sync init' to initialize or 'customrc sync init <url>' to clone"
    return 0
  fi

  echo ""
  _customrc_divider "$_CLI_PURPLE" "rc-modules git status"
  echo ""
  (cd "$modules_path" && git status)
  echo ""
  _customrc_divider "$_CLI_PURPLE"
  echo ""
}

_customrc_sync() {
  local subcommand="${1:-status}"
  shift 2>/dev/null || true

  case "$subcommand" in
    init)   _customrc_sync_init "$@" ;;
    push)   _customrc_sync_push ;;
    pull)   _customrc_sync_pull ;;
    status) _customrc_sync_status ;;
    *)
      _customrc_error "Unknown sync subcommand: $subcommand"
      echo "Usage: customrc sync <init|push|pull|status>"
      return 1
      ;;
  esac
}

# ─────────────────────────────────────────────────────────────────────────────
# Cache Commands
# ─────────────────────────────────────────────────────────────────────────────

_customrc_cache_clear() {
  local cache_path="$(_customrc_get_cache_path)"
  local name="${1:-}"

  if [[ -n "$name" ]]; then
    rm -f "$cache_path/${name}".* 2>/dev/null
    rm -f "$cache_path/.meta/${name}.meta" 2>/dev/null
    _customrc_success "Cleared cache: $name"
  else
    rm -rf "$cache_path"
    _customrc_success "Cleared all caches"
  fi
}

_customrc_cache_rebuild() {
  local helpers_path="$(_customrc_get_helpers_path)"
  local monolithic_cache="$(_customrc_get_cache_path)/monolithic.sh"

  _customrc_info "Clearing monolithic cache..."
  rm -f "$monolithic_cache" 2>/dev/null

  _customrc_info "Rebuilding monolithic cache..."
  if [[ -f "$helpers_path/monolithic.sh" ]]; then
    source "$helpers_path/cache.sh" 2>/dev/null || true
    source "$helpers_path/monolithic.sh"
    if generate_monolithic_file "$monolithic_cache"; then
      _customrc_success "Rebuilt monolithic cache"
    else
      _customrc_error "Failed to rebuild monolithic cache"
      return 1
    fi
  else
    _customrc_error "monolithic.sh helper not found"
    return 1
  fi
}

_customrc_cache_status() {
  local cache_path="$(_customrc_get_cache_path)"
  local monolithic_cache="$cache_path/monolithic.sh"

  echo ""
  echo -e "${_CLI_PURPLE}Cache Status:${_CLI_NC}"
  echo ""

  if [[ ! -d "$cache_path" ]]; then
    _customrc_warn "Cache directory does not exist: $cache_path"
    return 0
  fi

  # Show monolithic cache info
  if [[ -f "$monolithic_cache" ]]; then
    local size=$(stat -f %z "$monolithic_cache" 2>/dev/null || echo 0)
    local size_human
    if [[ "$size" -gt 1048576 ]]; then
      size_human="$((size / 1048576)) MB"
    elif [[ "$size" -gt 1024 ]]; then
      size_human="$((size / 1024)) KB"
    else
      size_human="${size} B"
    fi

    local file_time=$(stat -f %m "$monolithic_cache" 2>/dev/null || echo 0)
    local now=$(date +%s)
    local age=$((now - file_time))
    local age_human
    if [[ "$age" -gt 86400 ]]; then
      age_human="$((age / 86400)) days ago"
    elif [[ "$age" -gt 3600 ]]; then
      age_human="$((age / 3600)) hours ago"
    elif [[ "$age" -gt 60 ]]; then
      age_human="$((age / 60)) minutes ago"
    else
      age_human="${age} seconds ago"
    fi

    local line_count=$(wc -l < "$monolithic_cache" 2>/dev/null | tr -d ' ')

    echo "  Monolithic cache:"
    echo "    Path:    $monolithic_cache"
    echo "    Size:    $size_human"
    echo "    Lines:   $line_count"
    echo "    Created: $age_human"
  else
    _customrc_warn "Monolithic cache not found"
  fi

  echo ""

  # Show other caches using cache_list if available
  if type cache_list &>/dev/null; then
    echo "  Other caches:"
    cache_list
  fi
}

_customrc_cache() {
  local subcommand="${1:-status}"
  shift 2>/dev/null || true

  case "$subcommand" in
    clear)   _customrc_cache_clear "$@" ;;
    rebuild) _customrc_cache_rebuild ;;
    status)  _customrc_cache_status ;;
    *)
      _customrc_error "Unknown cache subcommand: $subcommand"
      echo "Usage: customrc cache <clear|rebuild|status>"
      return 1
      ;;
  esac
}

# ─────────────────────────────────────────────────────────────────────────────
# Modules Commands
# ─────────────────────────────────────────────────────────────────────────────

_customrc_modules_list() {
  local modules_path="$(_customrc_get_modules_path)"
  local customrc_path="$(_customrc_get_path)"

  if [[ ! -d "$modules_path" ]]; then
    _customrc_error "rc-modules directory not found: $modules_path"
    return 1
  fi

  # Source configs to get ignore lists
  source "$customrc_path/configs.sh" 2>/dev/null

  echo ""
  echo -e "${_CLI_PURPLE}Modules:${_CLI_NC}"

  local os_name=$(uname)
  local categories=("Global")

  case "$os_name" in
    Darwin) categories+=("Darwin") ;;
    Linux)  categories+=("Linux") ;;
  esac

  for category in "${categories[@]}"; do
    local category_path="$modules_path/$category"
    [[ ! -d "$category_path" ]] && continue

    echo ""
    echo -e "  ${_CLI_CYAN}$category/${_CLI_NC}"

    # Get ignore list for this category
    local -a ignore_list
    case "$category" in
      Global) ignore_list=("${CUSTOMRC_GLOBAL_IGNORE_LIST[@]}") ;;
      Darwin) ignore_list=("${CUSTOMRC_DARWIN_IGNORE_LIST[@]}") ;;
      Linux)  ignore_list=("${CUSTOMRC_LINUX_IGNORE_LIST[@]}") ;;
    esac

    for file in "$category_path"/*.sh; do
      [[ ! -f "$file" ]] && continue
      local filename=$(basename "$file")
      local is_ignored=false

      for ignored in "${ignore_list[@]}"; do
        if [[ "$filename" == "$ignored" ]]; then
          is_ignored=true
          break
        fi
      done

      if [[ "$is_ignored" == true ]]; then
        echo -e "    ${_CLI_RED}✗${_CLI_NC} $filename \033[0;90m(ignored)\033[0m"
      else
        echo -e "    ${_CLI_GREEN}✓${_CLI_NC} $filename"
      fi
    done
  done

  echo ""
}

_customrc_modules_edit() {
  local name="${1:-}"
  local modules_path="$(_customrc_get_modules_path)"

  if [[ -z "$name" ]]; then
    _customrc_error "Module name required"
    echo "Usage: customrc modules edit <name>"
    return 1
  fi

  # Add .sh extension if not provided
  [[ "$name" != *.sh ]] && name="${name}.sh"

  # Search for the module in all directories
  local found_path=""
  for dir in Global Darwin Linux; do
    local check_path="$modules_path/$dir/$name"
    if [[ -f "$check_path" ]]; then
      found_path="$check_path"
      break
    fi
  done

  if [[ -z "$found_path" ]]; then
    _customrc_error "Module not found: $name"
    _customrc_info "Search paths: Global/, Darwin/, Linux/"
    return 1
  fi

  _customrc_info "Opening $found_path..."
  ${EDITOR:-vim} "$found_path"
}

_customrc_modules_new() {
  local name="${1:-}"
  local modules_path="$(_customrc_get_modules_path)"

  if [[ -z "$name" ]]; then
    _customrc_error "Module name required"
    echo "Usage: customrc modules new <category/name> or <name>"
    echo "Example: customrc modules new Global/my-aliases"
    return 1
  fi

  local category="Global"
  local module_name="$name"

  # Parse category/name format
  if [[ "$name" == */* ]]; then
    category="${name%%/*}"
    module_name="${name#*/}"
  fi

  # Validate category
  case "$category" in
    Global|Darwin|Linux) ;;
    *)
      _customrc_error "Invalid category: $category"
      echo "Valid categories: Global, Darwin, Linux"
      return 1
      ;;
  esac

  # Add .sh extension if not provided
  [[ "$module_name" != *.sh ]] && module_name="${module_name}.sh"

  local target_dir="$modules_path/$category"
  local target_path="$target_dir/$module_name"

  # Create category directory if needed
  mkdir -p "$target_dir"

  if [[ -f "$target_path" ]]; then
    _customrc_error "Module already exists: $target_path"
    return 1
  fi

  # Create module from template
  local display_name="${module_name%.sh}"
  cat > "$target_path" << EOF
# ${display_name}
# CustomRC module - ${category}
# Created: $(date +%Y-%m-%d)

# Add your aliases, functions, and configurations below

EOF

  _customrc_success "Created module: $target_path"
  _customrc_info "Opening in editor..."
  ${EDITOR:-vim} "$target_path"
}

_customrc_modules() {
  local subcommand="${1:-list}"
  shift 2>/dev/null || true

  case "$subcommand" in
    list) _customrc_modules_list ;;
    edit) _customrc_modules_edit "$@" ;;
    new)  _customrc_modules_new "$@" ;;
    *)
      _customrc_error "Unknown modules subcommand: $subcommand"
      echo "Usage: customrc modules <list|edit|new>"
      return 1
      ;;
  esac
}

# ─────────────────────────────────────────────────────────────────────────────
# Debug Commands
# ─────────────────────────────────────────────────────────────────────────────

_customrc_debug_on() {
  local configs_path="$(_customrc_get_path)/configs.sh"

  if [[ ! -f "$configs_path" ]]; then
    _customrc_error "configs.sh not found: $configs_path"
    return 1
  fi

  sed -i '' 's/^CUSTOMRC_DEBUG_MODE=.*/CUSTOMRC_DEBUG_MODE=true/' "$configs_path"
  _customrc_success "Debug mode enabled"
  _customrc_info "Restart your shell to apply changes"
}

_customrc_debug_off() {
  local configs_path="$(_customrc_get_path)/configs.sh"

  if [[ ! -f "$configs_path" ]]; then
    _customrc_error "configs.sh not found: $configs_path"
    return 1
  fi

  sed -i '' 's/^CUSTOMRC_DEBUG_MODE=.*/CUSTOMRC_DEBUG_MODE=false/' "$configs_path"
  _customrc_success "Debug mode disabled"
  _customrc_info "Restart your shell to apply changes"
}

_customrc_debug_status() {
  local configs_path="$(_customrc_get_path)/configs.sh"

  if [[ ! -f "$configs_path" ]]; then
    _customrc_error "configs.sh not found: $configs_path"
    return 1
  fi

  local debug_mode=$(grep '^CUSTOMRC_DEBUG_MODE=' "$configs_path" | cut -d= -f2)

  echo ""
  echo -e "${_CLI_PURPLE}Debug Status:${_CLI_NC}"
  echo ""
  if [[ "$debug_mode" == "true" ]]; then
    echo -e "  Debug mode: ${_CLI_GREEN}enabled${_CLI_NC}"
  else
    echo -e "  Debug mode: \033[0;90mdisabled\033[0m"
  fi
  echo ""
}

_customrc_debug() {
  local subcommand="${1:-status}"
  shift 2>/dev/null || true

  case "$subcommand" in
    on)     _customrc_debug_on ;;
    off)    _customrc_debug_off ;;
    status) _customrc_debug_status ;;
    *)
      _customrc_error "Unknown debug subcommand: $subcommand"
      echo "Usage: customrc debug <on|off|status>"
      return 1
      ;;
  esac
}

# ─────────────────────────────────────────────────────────────────────────────
# Update Command
# ─────────────────────────────────────────────────────────────────────────────

_customrc_update() {
  local customrc_path="$(_customrc_get_path)"
  local force="${1:-}"

  # Check if CustomRC directory is a git repo
  if [[ ! -d "$customrc_path/.git" ]]; then
    _customrc_error "CustomRC is not a git repository: $customrc_path"
    _customrc_info "If you installed manually, please update using your original method."
    return 1
  fi

  # Check for uncommitted changes
  local uncommitted=$(cd "$customrc_path" && git status --porcelain 2>/dev/null | wc -l | tr -d ' ')
  if [[ "$uncommitted" -gt 0 && "$force" != "--force" ]]; then
    _customrc_warn "You have $uncommitted uncommitted change(s) in CustomRC"
    echo ""
    (cd "$customrc_path" && git status --short)
    echo ""
    _customrc_info "Commit or stash your changes first, or use 'customrc update --force'"
    return 1
  fi

  # Get current branch
  local branch=$(cd "$customrc_path" && git branch --show-current 2>/dev/null)
  if [[ -z "$branch" ]]; then
    _customrc_error "Could not determine current branch"
    return 1
  fi

  # Check if remote exists
  local remote=$(cd "$customrc_path" && git remote 2>/dev/null | head -n1)
  if [[ -z "$remote" ]]; then
    _customrc_error "No git remote configured"
    _customrc_info "Add a remote with: cd $customrc_path && git remote add origin <url>"
    return 1
  fi

  echo ""
  _customrc_divider "$_CLI_PURPLE" "CustomRC Update"
  echo ""

  # Fetch latest
  _customrc_info "Fetching from $remote/$branch..."
  if ! (cd "$customrc_path" && git fetch "$remote" "$branch" 2>&1); then
    _customrc_error "Failed to fetch updates"
    return 1
  fi

  # Check if there are updates
  local local_rev=$(cd "$customrc_path" && git rev-parse HEAD 2>/dev/null)
  local remote_rev=$(cd "$customrc_path" && git rev-parse "$remote/$branch" 2>/dev/null)

  if [[ "$local_rev" == "$remote_rev" ]]; then
    _customrc_success "CustomRC is already up to date"
    echo ""
    _customrc_divider "$_CLI_PURPLE"
    echo ""
    return 0
  fi

  # Show what will be updated
  local commits_behind=$(cd "$customrc_path" && git rev-list --count HEAD.."$remote/$branch" 2>/dev/null)
  _customrc_info "Found $commits_behind new commit(s)"
  echo ""
  (cd "$customrc_path" && git log --oneline HEAD.."$remote/$branch" | head -10)
  echo ""

  # Pull updates
  _customrc_info "Pulling updates..."
  if [[ "$force" == "--force" ]]; then
    if ! (cd "$customrc_path" && git reset --hard "$remote/$branch" 2>&1); then
      _customrc_error "Failed to update"
      return 1
    fi
  else
    if ! (cd "$customrc_path" && git pull "$remote" "$branch" 2>&1); then
      _customrc_error "Failed to pull updates"
      return 1
    fi
  fi

  _customrc_success "Updated CustomRC to latest version"

  # Rebuild cache
  echo ""
  _customrc_info "Rebuilding cache..."
  _customrc_cache_rebuild

  echo ""
  _customrc_divider "$_CLI_PURPLE"
  echo ""

  _customrc_success "Update complete!"
  _customrc_info "Restart your shell to apply changes"
}

# ─────────────────────────────────────────────────────────────────────────────
# Info Commands
# ─────────────────────────────────────────────────────────────────────────────

_customrc_status() {
  local customrc_path="$(_customrc_get_path)"
  local modules_path="$(_customrc_get_modules_path)"
  local cache_path="$(_customrc_get_cache_path)"

  echo ""
  _customrc_divider "$_CLI_PURPLE" "CustomRC Status"
  echo ""

  # Version
  echo -e "  Version:     ${_CLI_CYAN}${CUSTOMRC_VERSION:-unknown}${_CLI_NC}"

  # Paths
  echo -e "  Path:        $customrc_path"
  echo -e "  Modules:     $modules_path"
  echo -e "  Cache:       $cache_path"

  # Debug mode
  local debug_mode=$(grep '^CUSTOMRC_DEBUG_MODE=' "$customrc_path/configs.sh" 2>/dev/null | cut -d= -f2)
  if [[ "$debug_mode" == "true" ]]; then
    echo -e "  Debug:       ${_CLI_GREEN}enabled${_CLI_NC}"
  else
    echo -e "  Debug:       \033[0;90mdisabled\033[0m"
  fi

  # Git status of rc-modules
  if [[ -d "$modules_path/.git" ]]; then
    local branch=$(cd "$modules_path" && git branch --show-current 2>/dev/null)
    local status=$(cd "$modules_path" && git status --porcelain 2>/dev/null | wc -l | tr -d ' ')
    echo -e "  Sync:        ${_CLI_GREEN}git${_CLI_NC} (branch: $branch, $status uncommitted)"
  else
    echo -e "  Sync:        \033[0;90mnot a git repo\033[0m"
  fi

  # Module counts (use find to avoid zsh glob errors)
  local global_count=$(find "$modules_path/Global" -maxdepth 1 -name "*.sh" 2>/dev/null | wc -l | tr -d ' ')
  local darwin_count=$(find "$modules_path/Darwin" -maxdepth 1 -name "*.sh" 2>/dev/null | wc -l | tr -d ' ')
  local linux_count=$(find "$modules_path/Linux" -maxdepth 1 -name "*.sh" 2>/dev/null | wc -l | tr -d ' ')
  echo -e "  Modules:     Global: $global_count, Darwin: $darwin_count, Linux: $linux_count"

  echo ""
  _customrc_divider "$_CLI_PURPLE"
  echo ""
}

_customrc_doctor() {
  local customrc_path="$(_customrc_get_path)"
  local modules_path="$(_customrc_get_modules_path)"
  local helpers_path="$(_customrc_get_helpers_path)"
  local cache_path="$(_customrc_get_cache_path)"
  local errors=0

  echo ""
  _customrc_divider "$_CLI_PURPLE" "CustomRC Doctor"
  echo ""

  # Check CUSTOMRC_PATH
  if [[ -d "$customrc_path" ]]; then
    _customrc_success "CustomRC directory exists: $customrc_path"
  else
    _customrc_error "CustomRC directory not found: $customrc_path"
    ((errors++))
  fi

  # Check rc-modules
  if [[ -d "$modules_path" ]]; then
    _customrc_success "rc-modules directory exists"
  else
    _customrc_error "rc-modules directory not found: $modules_path"
    ((errors++))
  fi

  # Check required helpers
  local required_helpers=("cache.sh" "monolithic.sh")
  for helper in "${required_helpers[@]}"; do
    if [[ -f "$helpers_path/$helper" ]]; then
      _customrc_success "Helper found: $helper"
    else
      _customrc_error "Helper missing: $helper"
      ((errors++))
    fi
  done

  # Check module syntax
  echo ""
  _customrc_info "Checking module syntax..."
  local syntax_errors=0
  for dir in Global Darwin Linux; do
    local dir_path="$modules_path/$dir"
    [[ ! -d "$dir_path" ]] && continue
    for file in "$dir_path"/*.sh; do
      [[ ! -f "$file" ]] && continue
      if ! bash -n "$file" 2>/dev/null; then
        _customrc_error "Syntax error in: $file"
        ((syntax_errors++))
        ((errors++))
      fi
    done
  done
  if [[ "$syntax_errors" -eq 0 ]]; then
    _customrc_success "All modules have valid syntax"
  fi

  # Check cache directory is writable
  echo ""
  if [[ -d "$cache_path" ]]; then
    if [[ -w "$cache_path" ]]; then
      _customrc_success "Cache directory is writable"
    else
      _customrc_error "Cache directory is not writable: $cache_path"
      ((errors++))
    fi
  else
    # Try to create it
    if mkdir -p "$cache_path" 2>/dev/null; then
      _customrc_success "Cache directory can be created"
    else
      _customrc_error "Cannot create cache directory: $cache_path"
      ((errors++))
    fi
  fi

  # Check configs.sh
  if [[ -f "$customrc_path/configs.sh" ]]; then
    _customrc_success "configs.sh exists"
  else
    _customrc_error "configs.sh not found"
    ((errors++))
  fi

  echo ""
  _customrc_divider "$_CLI_PURPLE"
  echo ""

  if [[ "$errors" -eq 0 ]]; then
    _customrc_success "All checks passed!"
  else
    _customrc_error "$errors issue(s) found"
    return 1
  fi
}

_customrc_version() {
  echo "customrc ${CUSTOMRC_VERSION:-unknown}"
}

_customrc_help() {
  local command="${1:-}"

  if [[ -z "$command" ]]; then
    echo ""
    echo -e "${_CLI_PURPLE}CustomRC${_CLI_NC} - Modular shell configuration manager"
    echo ""
    echo -e "\033[1mUsage:${_CLI_NC}"
    echo "  customrc <command> [subcommand] [options]"
    echo ""
    echo -e "\033[1mCommands:${_CLI_NC}"
    echo "  sync     Manage rc-modules git synchronization"
    echo "  cache    Manage monolithic cache"
    echo "  modules  List, edit, or create modules"
    echo "  debug    Toggle debug mode"
    echo "  status   Show overall status summary"
    echo "  doctor   Run health checks"
    echo "  version  Show version"
    echo "  help     Show help for a command"
    echo ""
    echo -e "\033[1mExamples:${_CLI_NC}"
    echo "  customrc sync status        # Check rc-modules git status"
    echo "  customrc cache rebuild      # Rebuild monolithic cache"
    echo "  customrc modules list       # List all modules"
    echo "  customrc modules new my-mod # Create new module"
    echo "  customrc debug on           # Enable debug mode"
    echo "  customrc doctor             # Run health checks"
    echo ""
    return 0
  fi

  case "$command" in
    sync)
      echo ""
      echo -e "\033[1mCustomRC Sync${_CLI_NC} - Manage rc-modules git synchronization"
      echo ""
      echo -e "\033[1mUsage:${_CLI_NC}"
      echo "  customrc sync <subcommand> [options]"
      echo ""
      echo -e "\033[1mSubcommands:${_CLI_NC}"
      echo "  init [url]  Initialize rc-modules as git repo, or clone from URL"
      echo "  push        Push rc-modules to remote"
      echo "  pull        Pull latest rc-modules from remote"
      echo "  status      Show git status of rc-modules"
      echo ""
      ;;
    cache)
      echo ""
      echo -e "\033[1mCustomRC Cache${_CLI_NC} - Manage monolithic cache"
      echo ""
      echo -e "\033[1mUsage:${_CLI_NC}"
      echo "  customrc cache <subcommand> [options]"
      echo ""
      echo -e "\033[1mSubcommands:${_CLI_NC}"
      echo "  clear [name]  Clear all caches or a specific cache"
      echo "  rebuild       Rebuild the monolithic cache"
      echo "  status        Show cache status and info"
      echo ""
      ;;
    modules)
      echo ""
      echo -e "\033[1mCustomRC Modules${_CLI_NC} - Manage shell modules"
      echo ""
      echo -e "\033[1mUsage:${_CLI_NC}"
      echo "  customrc modules <subcommand> [options]"
      echo ""
      echo -e "\033[1mSubcommands:${_CLI_NC}"
      echo "  list        List all modules with load status"
      echo "  edit <name> Open a module in \$EDITOR"
      echo "  new <name>  Create a new module from template"
      echo ""
      echo -e "\033[1mExamples:${_CLI_NC}"
      echo "  customrc modules new Global/my-aliases"
      echo "  customrc modules edit docker.sh"
      echo ""
      ;;
    debug)
      echo ""
      echo -e "\033[1mCustomRC Debug${_CLI_NC} - Toggle debug mode"
      echo ""
      echo -e "\033[1mUsage:${_CLI_NC}"
      echo "  customrc debug <subcommand>"
      echo ""
      echo -e "\033[1mSubcommands:${_CLI_NC}"
      echo "  on      Enable debug mode"
      echo "  off     Disable debug mode"
      echo "  status  Show current debug mode status"
      echo ""
      ;;
    status)
      echo ""
      echo -e "\033[1mCustomRC Status${_CLI_NC} - Show overall status summary"
      echo ""
      echo -e "\033[1mUsage:${_CLI_NC}"
      echo "  customrc status"
      echo ""
      echo -e "\033[1mDisplays:${_CLI_NC}"
      echo "  - CustomRC version"
      echo "  - Installation paths (customrc, modules, cache)"
      echo "  - Debug mode status"
      echo "  - Git sync status of rc-modules"
      echo "  - Module counts by category (Global, Darwin, Linux)"
      echo ""
      ;;
    doctor)
      echo ""
      echo -e "\033[1mCustomRC Doctor${_CLI_NC} - Run health checks"
      echo ""
      echo -e "\033[1mUsage:${_CLI_NC}"
      echo "  customrc doctor"
      echo ""
      echo -e "\033[1mChecks:${_CLI_NC}"
      echo "  - CustomRC directory exists"
      echo "  - rc-modules directory exists"
      echo "  - Required helpers are present (cache.sh, monolithic.sh)"
      echo "  - Module syntax validation (bash -n)"
      echo "  - Cache directory is writable"
      echo "  - configs.sh exists"
      echo ""
      echo -e "\033[1mExit Codes:${_CLI_NC}"
      echo "  0  All checks passed"
      echo "  1  One or more issues found"
      echo ""
      ;;
    version)
      echo ""
      echo -e "\033[1mCustomRC Version${_CLI_NC} - Show version information"
      echo ""
      echo -e "\033[1mUsage:${_CLI_NC}"
      echo "  customrc version"
      echo "  customrc -v"
      echo "  customrc --version"
      echo ""
      echo -e "\033[1mOutput:${_CLI_NC}"
      echo "  Displays the current CustomRC version from \$CUSTOMRC_VERSION"
      echo ""
      ;;
    help)
      echo ""
      echo -e "\033[1mCustomRC Help${_CLI_NC} - Show help for commands"
      echo ""
      echo -e "\033[1mUsage:${_CLI_NC}"
      echo "  customrc help [command]"
      echo "  customrc -h"
      echo "  customrc --help"
      echo ""
      echo -e "\033[1mExamples:${_CLI_NC}"
      echo "  customrc help         # Show general help"
      echo "  customrc help sync    # Show sync command help"
      echo "  customrc help modules # Show modules command help"
      echo ""
      ;;
    *)
      _customrc_error "Unknown command: $command"
      echo "Run 'customrc help' for usage"
      return 1
      ;;
  esac
}

# ─────────────────────────────────────────────────────────────────────────────
# Main Dispatcher
# ─────────────────────────────────────────────────────────────────────────────

customrc() {
  local command="${1:-help}"
  shift 2>/dev/null || true

  case "$command" in
    sync)    _customrc_sync "$@" ;;
    cache)   _customrc_cache "$@" ;;
    modules) _customrc_modules "$@" ;;
    debug)   _customrc_debug "$@" ;;
    update)  _customrc_update "$@" ;;
    status)  _customrc_status ;;
    doctor)  _customrc_doctor ;;
    version) _customrc_version ;;
    help)    _customrc_help "$@" ;;
    -h|--help) _customrc_help "$@" ;;
    -v|--version) _customrc_version ;;
    *)
      _customrc_error "Unknown command: $command"
      echo "Run 'customrc help' for usage"
      return 1
      ;;
  esac
}
