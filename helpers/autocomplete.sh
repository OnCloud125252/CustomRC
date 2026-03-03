# CustomRC Autocomplete Helper
# Provides shell auto-completion for the customrc CLI
#
# Usage: source this file, then use autocomplete_install or customrc complete

# -----------------------------------------------------------------------------
# Shell Detection
# -----------------------------------------------------------------------------

# Detect the current shell type
# Returns: "bash", "zsh", or "unknown"
_autocomplete_detect_shell() {
  if [[ -n "${BASH_VERSION:-}" ]]; then
    echo "bash"
  elif [[ "$(basename "${SHELL:-}")" == "zsh" ]] || [[ -n "${ZSH_VERSION:-}" ]]; then
    echo "zsh"
  else
    echo "unknown"
  fi
}

# -----------------------------------------------------------------------------
# Completion Script Generators
# -----------------------------------------------------------------------------

# Generate Bash completion script
_autocomplete_get_bash_completions() {
  cat << 'EOF'
# CustomRC Bash completion
_customrc_complete() {
  local cur="${COMP_WORDS[COMP_CWORD]}"
  local prev="${COMP_WORDS[COMP_CWORD-1]}"
  local cmd="${COMP_WORDS[1]}"

  local commands="sync cache modules debug update status doctor version help complete"

  # Complete the first argument (command)
  if [[ $COMP_CWORD -eq 1 ]]; then
    COMPREPLY=($(compgen -W "$commands" -- "$cur"))
    return 0
  fi

  # Complete subcommands based on the command
  case "$cmd" in
    sync)
      local subcommands="init push pull status help"
      COMPREPLY=($(compgen -W "$subcommands" -- "$cur"))
      ;;
    cache)
      local subcommands="clear rebuild status help"
      COMPREPLY=($(compgen -W "$subcommands" -- "$cur"))
      ;;
    modules)
      local subcommands="list edit new help"
      if [[ "$prev" == "edit" ]] || [[ "$prev" == "new" ]]; then
        # Complete with module names
        local modules_path="${CUSTOMRC_PATH:-$HOME/.customrc}/rc-modules"
        local modules=()
        for dir in Global Darwin Linux; do
          [[ -d "$modules_path/$dir" ]] || continue
          for f in "$modules_path/$dir"/*.sh; do
            [[ -f "$f" ]] || continue
            modules+=("$dir/$(basename "$f" .sh)")
            modules+=("$(basename "$f" .sh)")
          done
        done
        COMPREPLY=($(compgen -W "${modules[*]}" -- "$cur"))
      else
        COMPREPLY=($(compgen -W "$subcommands" -- "$cur"))
      fi
      ;;
    debug)
      local subcommands="on off status help"
      COMPREPLY=($(compgen -W "$subcommands" -- "$cur"))
      ;;
    complete)
      local subcommands="install status uninstall help"
      COMPREPLY=($(compgen -W "$subcommands" -- "$cur"))
      ;;
    *)
      COMPREPLY=()
      ;;
  esac
}

complete -F _customrc_complete customrc
EOF
}

# Generate Zsh completion script
_autocomplete_get_zsh_completions() {
  cat << 'EOF'
#compdef customrc

# CustomRC Zsh completion
_customrc_complete() {
  local curcontext="$curcontext" state line
  typeset -A opt_args

  local -a commands
  commands=(
    'sync:Manage rc-modules git synchronization'
    'cache:Manage monolithic cache'
    'modules:List, edit, or create modules'
    'debug:Toggle debug mode'
    'update:Update CustomRC to latest version'
    'status:Show overall status summary'
    'doctor:Run health checks'
    'version:Show version'
    'help:Show help for commands'
    'complete:Manage shell completions'
  )

  _arguments -C \
    '1: :->command' \
    '*: :->args' && return 0

  case "$state" in
    command)
      _describe -t commands 'customrc commands' commands
      ;;
    args)
      case "$line[1]" in
        sync)
          local -a sync_cmds
          sync_cmds=(
            'init:Initialize rc-modules as git repo or clone from URL'
            'push:Push rc-modules to remote'
            'pull:Pull latest rc-modules from remote'
            'status:Show git status of rc-modules'
            'help:Show sync help'
          )
          _describe -t sync_cmds 'sync subcommands' sync_cmds
          ;;
        cache)
          local -a cache_cmds
          cache_cmds=(
            'clear:Clear all caches or a specific cache'
            'rebuild:Rebuild the monolithic cache'
            'status:Show cache status and info'
            'help:Show cache help'
          )
          _describe -t cache_cmds 'cache subcommands' cache_cmds
          ;;
        modules)
          local -a modules_cmds
          modules_cmds=(
            'list:List all modules with load status'
            'edit:Open a module in editor'
            'new:Create a new module from template'
            'help:Show modules help'
          )
          _describe -t modules_cmds 'modules subcommands' modules_cmds

          # Complete module names for edit subcommand
          if [[ "$line[2]" == "edit" ]]; then
            local modules_path="${CUSTOMRC_PATH:-$HOME/.customrc}/rc-modules"
            local -a module_names
            for dir in Global Darwin Linux; do
              [[ -d "$modules_path/$dir" ]] || continue
              for f in "$modules_path/$dir"/*.sh(N); do
                [[ -f "$f" ]] || continue
                module_names+=("$dir/$(basename "$f" .sh)")
              done
            done
            _describe -t modules 'modules' module_names
          fi
          ;;
        debug)
          local -a debug_cmds
          debug_cmds=(
            'on:Enable debug mode'
            'off:Disable debug mode'
            'status:Show current debug mode status'
            'help:Show debug help'
          )
          _describe -t debug_cmds 'debug subcommands' debug_cmds
          ;;
        complete)
          local -a complete_cmds
          complete_cmds=(
            'install:Install completions for current shell'
            'status:Check if completions are installed'
            'uninstall:Remove completions'
            'help:Show complete help'
          )
          _describe -t complete_cmds 'complete subcommands' complete_cmds
          ;;
      esac
      ;;
  esac
}

_customrc_complete "$@"
EOF
}

# -----------------------------------------------------------------------------
# Installation Paths
# -----------------------------------------------------------------------------

# Get the appropriate completion directory for the current shell
_autocomplete_get_completion_dir() {
  local shell_type="${1:-$(_autocomplete_detect_shell)}"
  local completion_dir=""

  case "$shell_type" in
    bash)
      # Check common Bash completion directories
      if [[ -d "/etc/bash_completion.d" ]]; then
        completion_dir="/etc/bash_completion.d"
      elif [[ -d "/usr/local/etc/bash_completion.d" ]]; then
        completion_dir="/usr/local/etc/bash_completion.d"
      elif [[ -d "$HOME/.bash_completion.d" ]]; then
        completion_dir="$HOME/.bash_completion.d"
      else
        # Default to user-local
        completion_dir="$HOME/.bash_completion.d"
      fi
      ;;
    zsh)
      # Check common Zsh completion directories
      if [[ -d "/usr/local/share/zsh/site-functions" ]]; then
        completion_dir="/usr/local/share/zsh/site-functions"
      elif [[ -d "/usr/share/zsh/site-functions" ]]; then
        completion_dir="/usr/share/zsh/site-functions"
      elif [[ -d "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/completions" ]]; then
        completion_dir="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/completions"
      else
        # Use Zsh's fpath
        local zsh_fpath_dir="${FPATH%%:*}"
        if [[ -d "$zsh_fpath_dir" ]]; then
          completion_dir="$zsh_fpath_dir"
        else
          completion_dir="$HOME/.zsh/completions"
        fi
      fi
      ;;
    *)
      return 1
      ;;
  esac

  echo "$completion_dir"
}

# Get the completion filename for the current shell
_autocomplete_get_completion_file() {
  local shell_type="${1:-$(_autocomplete_detect_shell)}"

  case "$shell_type" in
    bash)
      echo "customrc"
      ;;
    zsh)
      echo "_customrc"
      ;;
    *)
      echo ""
      return 1
      ;;
  esac
}

# -----------------------------------------------------------------------------
# Installation Status
# -----------------------------------------------------------------------------

# Check if completions are already installed
_autocomplete_is_installed() {
  local shell_type="${1:-$(_autocomplete_detect_shell)}"
  local completion_dir
  completion_dir="$(_autocomplete_get_completion_dir "$shell_type")"
  local completion_file
  completion_file="$(_autocomplete_get_completion_file "$shell_type")"

  [[ -f "$completion_dir/$completion_file" ]]
}

# Get the installed completion file path (if installed)
_autocomplete_get_installed_path() {
  local shell_type="${1:-$(_autocomplete_detect_shell)}"
  local completion_dir
  completion_dir="$(_autocomplete_get_completion_dir "$shell_type")"
  local completion_file
  completion_file="$(_autocomplete_get_completion_file "$shell_type")"

  if [[ -f "$completion_dir/$completion_file" ]]; then
    echo "$completion_dir/$completion_file"
  else
    echo ""
  fi
}

# Mark that auto-check has run (using a flag file)
_autocomplete_mark_checked() {
  local flag_file="${CUSTOMRC_CACHE_DIR:-$HOME/.cache/customrc}/.autocomplete_checked"
  mkdir -p "$(dirname "$flag_file")"
  touch "$flag_file"
}

# Check if auto-check has already run this session
_autocomplete_has_checked() {
  local flag_file="${CUSTOMRC_CACHE_DIR:-$HOME/.cache/customrc}/.autocomplete_checked"
  [[ -f "$flag_file" ]]
}

# -----------------------------------------------------------------------------
# Public Functions
# -----------------------------------------------------------------------------

# Install completions for the current shell
autocomplete_install() {
  local shell_type
  shell_type="$(_autocomplete_detect_shell)"

  if [[ "$shell_type" == "unknown" ]]; then
    echo -e "\033[0;31m[✗]\033[0m Unable to detect shell type"
    return 1
  fi

  local completion_dir
  completion_dir="$(_autocomplete_get_completion_dir "$shell_type")"
  local completion_file
  completion_file="$(_autocomplete_get_completion_file "$shell_type")"

  # Create completion directory if it doesn't exist
  if [[ ! -d "$completion_dir" ]]; then
    mkdir -p "$completion_dir" 2>/dev/null || {
      echo -e "\033[0;31m[✗]\033[0m Failed to create completion directory: $completion_dir"
      return 1
    }
  fi

  local target_path="$completion_dir/$completion_file"

  # Generate and install completion script
  case "$shell_type" in
    bash)
      _autocomplete_get_bash_completions > "$target_path"
      ;;
    zsh)
      _autocomplete_get_zsh_completions > "$target_path"
      ;;
  esac

  # Make readable
  chmod 644 "$target_path"

  echo -e "\033[0;32m[✓]\033[0m Installed ${shell_type} completions to: $target_path"
  echo -e "\033[0;36m[i]\033[0m Restart your shell or source your rc file to activate completions"

  # Mark as checked so we don't prompt again
  _autocomplete_mark_checked
}

# Show completion installation status
autocomplete_status() {
  local shell_type
  shell_type="$(_autocomplete_detect_shell)"

  echo ""
  echo -e "\033[0;35mCompletion Status:\033[0m"
  echo ""
  echo -e "  Detected shell: \033[0;36m${shell_type}\033[0m"

  if [[ "$shell_type" == "unknown" ]]; then
    echo -e "  Status: \033[0;31m✗\033[0m Unable to detect shell"
    echo ""
    return 1
  fi

  local completion_dir
  completion_dir="$(_autocomplete_get_completion_dir "$shell_type")"
  local installed_path
  installed_path="$(_autocomplete_get_installed_path "$shell_type")"

  echo -e "  Completion dir: $completion_dir"

  if [[ -n "$installed_path" ]]; then
    echo -e "  Status: \033[0;32m✓\033[0m Installed"
    echo -e "  Location: $installed_path"
  else
    echo -e "  Status: \033[0;33m!\033[0m Not installed"
  fi

  echo ""
}

# Remove completions for the current shell
autocomplete_uninstall() {
  local shell_type
  shell_type="$(_autocomplete_detect_shell)"

  if [[ "$shell_type" == "unknown" ]]; then
    echo -e "\033[0;31m[✗]\033[0m Unable to detect shell type"
    return 1
  fi

  local installed_path
  installed_path="$(_autocomplete_get_installed_path "$shell_type")"

  if [[ -z "$installed_path" ]]; then
    echo -e "\033[0;33m[!]\033[0m Completions are not installed"
    return 0
  fi

  if trash "$installed_path" 2>/dev/null || rm -f "$installed_path"; then
    echo -e "\033[0;32m[✓]\033[0m Removed ${shell_type} completions from: $installed_path"
  else
    echo -e "\033[0;31m[✗]\033[0m Failed to remove: $installed_path"
    return 1
  fi
}

# One-time auto-prompt on first use
autocomplete_check_and_offer() {
  # Skip if already checked
  if _autocomplete_has_checked; then
    return 0
  fi

  local shell_type
  shell_type="$(_autocomplete_detect_shell)"

  if [[ "$shell_type" == "unknown" ]]; then
    _autocomplete_mark_checked
    return 0
  fi

  # Skip if already installed
  if _autocomplete_is_installed "$shell_type"; then
    _autocomplete_mark_checked
    return 0
  fi

  # Show one-time message
  echo ""
  echo -e "\033[0;36m[i]\033[0m Shell completions are available for CustomRC"
  echo -e "    Run \033[0;33mcustomrc complete install\033[0m to enable tab completion"
  echo ""

  _autocomplete_mark_checked
}
