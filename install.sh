#!/bin/bash
#
# CustomRC Installer
# Installs CustomRC and sets up your shell configuration
#
# Usage: ./install.sh
#

set -e

# ─────────────────────────────────────────────────────────────────────────────
# Configuration
# ─────────────────────────────────────────────────────────────────────────────

CUSTOMRC_DIR="${CUSTOMRC_DIR:-$HOME/.customrc}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Basic Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[0;37m'
NC='\033[0m' # No Color
BOLD='\033[1m'

# Symbols
CHECK="${GREEN}[✓]${NC}"
CROSS="${RED}[✗]${NC}"
WARN="${YELLOW}[!]${NC}"
INFO="${CYAN}[i]${NC}"


# ─────────────────────────────────────────────────────────────────────────────
# Helper Functions
# ─────────────────────────────────────────────────────────────────────────────

info() {
  echo -e "${INFO} $1"
}

success() {
  echo -e "${CHECK} $1"
}

warn() {
  echo -e "${WARN} $1"
}

error() {
  echo -e "${CROSS} $1"
  exit 1
}

# Prints a full-width divider line with a centered label
print_divider() {
  local color="${1:-$PURPLE}" label="${2:-customrc}"
  local terminal_width=${CUSTOMRC_TERMINAL_WIDTH:-80}
  local padding_width=$((terminal_width - ${#label} - 6))
  local spaces
  printf -v spaces '%*s' "$padding_width" ''
  printf '%b━━━━[%s]%s%b\n' "$color" "$label" "${spaces// /━}" "$NC"
}

# ─────────────────────────────────────────────────────────────────────────────
# Prerequisite Checks
# ─────────────────────────────────────────────────────────────────────────────

check_prerequisites() {
  info "Checking prerequisites..."

  # Check for bash 4+ or zsh 5+
  local shell_ok=false

  if [[ -n "$BASH_VERSION" ]]; then
    local bash_major="${BASH_VERSION%%.*}"
    if [[ "$bash_major" -ge 4 ]]; then
      success "Bash $BASH_VERSION detected"
      shell_ok=true
    fi
  fi

  if command -v zsh &>/dev/null; then
    local zsh_version=$(zsh --version | cut -d' ' -f2)
    local zsh_major="${zsh_version%%.*}"
    if [[ "$zsh_major" -ge 5 ]]; then
      success "Zsh $zsh_version detected"
      shell_ok=true
    fi
  fi

  if [[ "$shell_ok" != true ]]; then
    error "CustomRC requires Bash 4+ or Zsh 5+. Please upgrade your shell."
  fi
}

# ─────────────────────────────────────────────────────────────────────────────
# Installation Steps
# ─────────────────────────────────────────────────────────────────────────────

setup_modules() {
  info "Setting up rc-modules..."

  if [[ -d "$CUSTOMRC_DIR/rc-modules" ]]; then
    warn "rc-modules/ already exists, skipping copy"
    info "To reset, remove rc-modules/ and run installer again"
  else
    if [[ -d "$CUSTOMRC_DIR/rc-modules.example" ]]; then
      cp -r "$CUSTOMRC_DIR/rc-modules.example" "$CUSTOMRC_DIR/rc-modules"
      success "Created rc-modules/ from template"
    else
      error "rc-modules.example/ not found. Is CustomRC installed correctly?"
    fi
  fi
}

detect_shell_rc() {
  # Detect the user's primary shell and its rc file
  local shell_name=$(basename "$SHELL")

  case "$shell_name" in
    zsh)
      echo "$HOME/.zshrc"
      ;;
    bash)
      # macOS uses .bash_profile, Linux typically uses .bashrc
      if [[ "$(uname)" == "Darwin" ]]; then
        echo "$HOME/.bash_profile"
      else
        echo "$HOME/.bashrc"
      fi
      ;;
    *)
      echo "$HOME/.${shell_name}rc"
      ;;
  esac
}

backup_rc_file() {
  local rc_file="$1"

  if [[ -f "$rc_file" ]]; then
    local backup_file="${rc_file}.backup.$(date +%Y%m%d_%H%M%S)"
    cp "$rc_file" "$backup_file"
    success "Backed up $rc_file to $backup_file"
  fi
}

add_source_line() {
  local rc_file="$1"
  local source_block="
# CustomRC - Modular shell configuration
# https://github.com/OnCloud125252/CustomRC
export CUSTOMRC_PATH=\"$CUSTOMRC_DIR\"
source \"\$CUSTOMRC_PATH/customrc.sh\""

  # Check if CustomRC is already sourced
  if grep -q "CUSTOMRC_PATH" "$rc_file" 2>/dev/null; then
    warn "CustomRC already configured in $rc_file"
    return 0
  fi

  # Create rc file if it doesn't exist
  if [[ ! -f "$rc_file" ]]; then
    touch "$rc_file"
    success "Created $rc_file"
  fi

  # Add source line
  echo "$source_block" >> "$rc_file"
  success "Added CustomRC to $rc_file"
}

# ─────────────────────────────────────────────────────────────────────────────
# Main Installation
# ─────────────────────────────────────────────────────────────────────────────

main() {
  echo ""
  echo -e "${BOLD}${CYAN}CustomRC Installer${NC}"
  print_divider "$PURPLE" "installation"

  # Change to script directory if running from elsewhere
  if [[ "$SCRIPT_DIR" != "$CUSTOMRC_DIR" ]]; then
    CUSTOMRC_DIR="$SCRIPT_DIR"
  fi

  check_prerequisites
  setup_modules

  local rc_file=$(detect_shell_rc)
  info "Detected shell config: $rc_file"

  backup_rc_file "$rc_file"
  add_source_line "$rc_file"

  print_divider "$PURPLE" "installation"
  echo -e "${GREEN}${BOLD}Installation complete!${NC}"
  echo ""
  echo -e "${BOLD}Next steps:${NC}"
  echo ""
  echo "  1. Restart your shell or run:"
  echo -e "     ${CYAN}source $rc_file${NC}"
  echo ""
  echo "  2. Customize your modules in:"
  echo -e "     ${CYAN}$CUSTOMRC_DIR/rc-modules/${NC}"
  echo ""
  echo "  3. Read the documentation:"
  echo -e "     ${CYAN}$CUSTOMRC_DIR/docs/user-guide.md${NC}"
  echo ""
}

main "$@"
