# CustomRC Complete Command
# CLI integration for autocomplete functionality
#
# This is sourced by customrc-cli.sh to provide the 'complete' command

# Source the autocomplete helper
CUSTOMRC_HELPERS_PATH="${CUSTOMRC_HELPERS_PATH:-$(_customrc_get_helpers_path)}"
source "$CUSTOMRC_HELPERS_PATH/autocomplete.sh" 2>/dev/null || {
  _customrc_error "autocomplete.sh helper not found"
  return 1
}

# Show help for the complete command
_customrc_complete_help() {
  echo ""
  echo -e "\033[1mCustomRC Complete\033[0m - Manage shell completions"
  echo ""
  echo -e "\033[1mUsage:\033[0m"
  echo "  customrc complete <subcommand>"
  echo ""
  echo -e "\033[1mSubcommands:\033[0m"
  echo "  install    Install completions for detected shell (bash/zsh)"
  echo "  status     Check if completions are installed"
  echo "  uninstall  Remove completions for current shell"
  echo "  help       Show this help message"
  echo ""
  echo -e "\033[1mExamples:\033[0m"
  echo "  customrc complete install    # Install completions"
  echo "  customrc complete status     # Check installation status"
  echo ""
  echo -e "\033[1mNotes:\033[0m"
  echo "  - Completions will be installed to your shell's standard"
  echo "    completion directory (e.g., ~/.zsh/completions or"
  echo "    /usr/local/etc/bash_completion.d/)"
  echo "  - After installing, restart your shell or source your rc file"
  echo ""
}

# Main complete command dispatcher
_customrc_complete() {
  local subcommand="${1:-status}"
  shift 2>/dev/null || true

  case "$subcommand" in
    install)
      autocomplete_install
      ;;
    status)
      autocomplete_status
      ;;
    uninstall)
      autocomplete_uninstall
      ;;
    help|-h|--help)
      _customrc_complete_help
      ;;
    *)
      _customrc_error "Unknown complete subcommand: $subcommand"
      echo "Usage: customrc complete <install|status|uninstall|help>"
      return 1
      ;;
  esac
}
