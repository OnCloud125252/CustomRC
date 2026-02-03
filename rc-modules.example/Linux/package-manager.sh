# Package Manager Configuration
# Setup for common Linux package managers
#
# Usage: Uncomment the section that matches your distribution's package manager.

# ─────────────────────────────────────────────────────────────────────────────
# APT (Debian, Ubuntu, and derivatives)
# ─────────────────────────────────────────────────────────────────────────────

# alias apt-up="sudo apt update && sudo apt upgrade -y"
# alias apt-clean="sudo apt autoremove -y && sudo apt autoclean"
# alias apt-search="apt search"

# ─────────────────────────────────────────────────────────────────────────────
# DNF (Fedora, RHEL 8+, and derivatives)
# ─────────────────────────────────────────────────────────────────────────────

# alias dnf-up="sudo dnf upgrade -y"
# alias dnf-clean="sudo dnf autoremove -y && sudo dnf clean all"
# alias dnf-search="dnf search"

# ─────────────────────────────────────────────────────────────────────────────
# Pacman (Arch Linux and derivatives)
# ─────────────────────────────────────────────────────────────────────────────

# alias pac-up="sudo pacman -Syu"
# alias pac-clean="sudo pacman -Sc"
# alias pac-search="pacman -Ss"
# alias pac-orphans="sudo pacman -Rns \$(pacman -Qtdq)"

# ─────────────────────────────────────────────────────────────────────────────
# Add your custom package manager configuration below
# ─────────────────────────────────────────────────────────────────────────────
