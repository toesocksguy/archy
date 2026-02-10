#!/usr/bin/env bash
#
# Arch Linux Environment Setup Script
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$SCRIPT_DIR/config"

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

    # Network
    networkmanager
    network-manager-applet
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

    # Copy custom config.h if available in repo
    if [[ -f "$CONFIG_DIR/dwm/config.h" ]]; then
        cp "$CONFIG_DIR/dwm/config.h" "$dwm_dir/config.h"
        log_info "Applied custom dwm config.h"
    fi

    # Compile and install
    log_info "Compiling dwm..."
    cd "$dwm_dir"
    sudo make clean install
    cd - >/dev/null

    log_ok "dwm installed"
}

install_slstatus() {
    local slstatus_dir="$HOME/.config/slstatus"

    log_info "Setting up slstatus..."

    # Create directory if it doesn't exist
    if [[ ! -d "$slstatus_dir" ]]; then
        mkdir -p "$slstatus_dir"
    fi

    # Clone if directory is empty
    if [[ -z "$(ls -A "$slstatus_dir" 2>/dev/null)" ]]; then
        log_info "Cloning slstatus..."
        git clone https://git.suckless.org/slstatus "$slstatus_dir"
    fi

    # Copy custom config.h if available in repo
    if [[ -f "$CONFIG_DIR/slstatus/config.h" ]]; then
        cp "$CONFIG_DIR/slstatus/config.h" "$slstatus_dir/config.h"
        log_info "Applied custom slstatus config.h"
    fi

    # Compile and install
    log_info "Compiling slstatus..."
    cd "$slstatus_dir"
    sudo make clean install
    cd - >/dev/null

    log_ok "slstatus installed"
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
    # Note: using $HOME instead of ~ because .desktop files don't expand ~
    if [[ ! -f /usr/share/xsessions/dwm.desktop ]]; then
        log_info "Creating dwm.desktop..."
        sudo tee /usr/share/xsessions/dwm.desktop > /dev/null << EOF
[Desktop Entry]
Encoding=UTF-8
Name=DWM
Comment=the dynamic window manager
Exec=$HOME/.config/dwm/autostart.sh
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
slstatus &
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

configure_lightdm() {
    log_info "Configuring LightDM..."

    local conf="/etc/lightdm/lightdm.conf"

    # Set slick-greeter as the greeter
    if ! grep -q "^greeter-session=lightdm-slick-greeter" "$conf" 2>/dev/null; then
        sudo sed -i '/^\[Seat:\*\]/a greeter-session=lightdm-slick-greeter' "$conf"
        log_info "Set greeter to slick-greeter"
    fi

    # Set dwm as the default session
    if ! grep -q "^user-session=dwm" "$conf" 2>/dev/null; then
        sudo sed -i '/^\[Seat:\*\]/a user-session=dwm' "$conf"
        log_info "Set default session to dwm"
    fi

    log_ok "LightDM configured"
}

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
# Dotfiles
# ─────────────────────────────────────────────────────────────────────────────

deploy_configs() {
    log_info "Deploying config files..."

    # Config files to copy: source (in repo) -> destination
    local -A configs=(
        ["$CONFIG_DIR/emacs/init.el"]="$HOME/.config/emacs/init.el"
        ["$CONFIG_DIR/ghostty/config"]="$HOME/.config/ghostty/config"
        ["$CONFIG_DIR/picom/picom.conf"]="$HOME/.config/picom/picom.conf"
        ["$CONFIG_DIR/rofi/config.rasi"]="$HOME/.config/rofi/config.rasi"
    )

    for src in "${!configs[@]}"; do
        local dest="${configs[$src]}"

        if [[ ! -f "$src" ]]; then
            log_info "Skipping $(basename "$src") (not in repo)"
            continue
        fi

        mkdir -p "$(dirname "$dest")"
        cp "$src" "$dest"
        log_info "Deployed $(basename "$src")"
    done

    log_ok "Config files deployed"
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
    install_slstatus
    setup_dwm_session
    deploy_configs
    configure_lightdm
    enable_services
    log_ok "Setup complete!"
}

main "$@"
