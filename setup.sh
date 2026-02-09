#!/usr/bin/env bash
#
# Arch Linux Environment Setup Script
#

set -euo pipefail

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_ok() { echo -e "${GREEN}[OK]${NC} $1"; }

# ─────────────────────────────────────────────────────────────────────────────
# Packages
# ─────────────────────────────────────────────────────────────────────────────

PACKAGES=(
    # Core
    base-devel
    git

    # X11
    xorg-server
    xorg-xinit
    xorg-xrandr
    xorg-xsetroot

    # dwm dependencies
    libx11
    libxft
    libxinerama

    # Apps
    emacs
    picom
    rofi
    thunar

    # Utils
    fzf
    ripgrep
    feh

    # Fonts
    ttf-jetbrains-mono-nerd

    # Audio
    pipewire
    pipewire-pulse
    pavucontrol
)

install_packages() {
    log_info "Installing packages..."
    sudo pacman -S --needed --noconfirm "${PACKAGES[@]}"
    log_ok "Packages installed"
}

# ─────────────────────────────────────────────────────────────────────────────
# Main
# ─────────────────────────────────────────────────────────────────────────────

main() {
    echo "Arch Linux Setup"
    echo "================"

    install_packages
    log_ok "Setup complete!"
}

main "$@"
