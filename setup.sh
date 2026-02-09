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

# Packages that conflict with our desired packages
# (e.g., pulseaudio conflicts with pipewire-pulse)
CONFLICTING_PACKAGES=(
    pulseaudio
    pulseaudio-bluetooth
)

# Remove conflicting packages before installing new ones
# This prevents pacman from failing due to package conflicts
remove_conflicting() {
    log_info "Checking for conflicting packages..."
    local to_remove=()

    # Check which conflicting packages are installed
    for pkg in "${CONFLICTING_PACKAGES[@]}"; do
        if pacman -Qi "$pkg" &>/dev/null; then
            to_remove+=("$pkg")
        fi
    done

    # Remove them if any were found
    # -R: remove, -n: remove config files, -s: remove unneeded dependencies
    if [[ ${#to_remove[@]} -gt 0 ]]; then
        log_info "Removing: ${to_remove[*]}"
        sudo pacman -Rns --noconfirm "${to_remove[@]}"
    fi
}

install_packages() {
    log_info "Installing packages..."
    remove_conflicting
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
