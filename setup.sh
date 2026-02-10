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
    fontconfig
    freetype2

    # Apps
    emacs
    ghostty
    picom
    rofi
    thunar

    # Display manager
    lightdm
    lightdm-slick-greeter

    # Utils
    fzf
    ripgrep
    feh
    mise

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

update_system() {
    log_info "Updating system..."
    sudo pacman -Syu --noconfirm
    log_ok "System updated"
}

install_packages() {
    log_info "Installing packages..."
    remove_conflicting
    sudo pacman -S --needed --noconfirm "${PACKAGES[@]}"
    log_ok "Packages installed"
}

# ─────────────────────────────────────────────────────────────────────────────
# AUR Helper
# ─────────────────────────────────────────────────────────────────────────────

install_yay() {
    if command -v yay &>/dev/null; then
        log_ok "yay already installed"
        return
    fi

    log_info "Installing yay..."
    local tmp_dir
    tmp_dir=$(mktemp -d)
    git clone https://aur.archlinux.org/yay.git "$tmp_dir/yay"
    cd "$tmp_dir/yay"
    makepkg -si --noconfirm
    cd - >/dev/null
    rm -rf "$tmp_dir"
    log_ok "yay installed"
}

# ─────────────────────────────────────────────────────────────────────────────
# Suckless
# ─────────────────────────────────────────────────────────────────────────────

install_dwm() {
    local dwm_dir="$HOME/.config/dwm"

    log_info "Setting up dwm..."

    # Create directory if it doesn't exist
    if [[ ! -d "$dwm_dir" ]]; then
        mkdir -p "$dwm_dir"
    fi

    # Clone if directory is empty
    if [[ -z "$(ls -A "$dwm_dir" 2>/dev/null)" ]]; then
        log_info "Cloning dwm..."
        git clone https://git.suckless.org/dwm "$dwm_dir"
    fi

    # Compile and install
    log_info "Compiling dwm..."
    cd "$dwm_dir"
    sudo make clean install
    cd - >/dev/null

    log_ok "dwm installed"
}

# ─────────────────────────────────────────────────────────────────────────────
# Desktop Session
# ─────────────────────────────────────────────────────────────────────────────

setup_dwm_session() {
    log_info "Setting up dwm session..."

    # Create xsessions directory if needed
    if [[ ! -d /usr/share/xsessions ]]; then
        sudo mkdir -p /usr/share/xsessions
    fi

    # Create .desktop file for display manager
    if [[ ! -f /usr/share/xsessions/dwm.desktop ]]; then
        log_info "Creating dwm.desktop..."
        sudo tee /usr/share/xsessions/dwm.desktop > /dev/null << 'EOF'
[Desktop Entry]
Encoding=UTF-8
Name=DWM
Comment=the dynamic window manager
Exec=~/.config/dwm/autostart.sh
Icon=dwm
Type=XSession
EOF
    fi

    # Create autostart.sh
    local autostart="$HOME/.config/dwm/autostart.sh"
    if [[ ! -f "$autostart" ]]; then
        log_info "Creating autostart.sh..."
        mkdir -p "$HOME/.config/dwm"
        cat > "$autostart" << 'EOF'
#!/bin/sh
picom -b &
feh --randomize --bg-fill ~/Pictures/backgrounds/* &
nm-applet --indicator &
exec dwm
EOF
        chmod +x "$autostart"
    fi

    log_ok "dwm session configured"
}

# ─────────────────────────────────────────────────────────────────────────────
# Services
# ─────────────────────────────────────────────────────────────────────────────

enable_services() {
    log_info "Enabling services..."

    # NetworkManager
    if ! systemctl is-enabled NetworkManager &>/dev/null; then
        sudo systemctl enable NetworkManager
        log_info "Enabled NetworkManager"
    fi

    # LightDM
    if ! systemctl is-enabled lightdm &>/dev/null; then
        sudo systemctl enable lightdm
        log_info "Enabled LightDM"
    fi

    # Pipewire (user service - enabled by default on Arch, but just in case)
    if ! systemctl --user is-enabled pipewire &>/dev/null 2>&1; then
        systemctl --user enable pipewire pipewire-pulse
        log_info "Enabled pipewire"
    fi

    log_ok "Services enabled"
}

# ─────────────────────────────────────────────────────────────────────────────
# Main
# ─────────────────────────────────────────────────────────────────────────────

main() {
    echo "Arch Linux Setup"
    echo "================"

    update_system
    install_packages
    install_yay
    install_dwm
    setup_dwm_session
    enable_services
    log_ok "Setup complete!"
}

main "$@"
