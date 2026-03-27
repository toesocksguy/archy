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
RED='\033[0;31m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_ok()   { echo -e "${GREEN}[OK]${NC} $1"; }
log_err()  { echo -e "${RED}[ERR]${NC} $1" >&2; }

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
    libxcb
    xcb-util-wm
    libxres

    # Apps
    emacs
    kitty
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
    xclip
    maim
    slop
    dmenu

    # Browsers
    firefox

    # Notifications
    dunst

    # Polkit agent
    lxsession

    # XDG user directories
    xdg-user-dirs

    # Thunar support
    gvfs
    tumbler
    thunar-archive-plugin
    thunar-volman
    xarchiver

    # Filesystem support
    ntfs-3g

    # Fonts
    ttf-jetbrains-mono-nerd
    noto-fonts
    noto-fonts-emoji

    # Utilities
    unzip
    zip
    man-db
    wget
    which
    tree
    htop
    xdotool
    fastfetch
    mpv
    bash-completion

    # Shell/CLI tools
    bat
    eza
    zoxide
    fd

    # GTK theme build dependencies
    sassc
    gnome-themes-extra

    # Audio
    pipewire
    pipewire-pulse
    pipewire-alsa
    wireplumber
    pavucontrol

    # Network
    networkmanager
    network-manager-applet

    # Bluetooth
    bluez
    bluez-utils
    blueman

    # Containers
    docker
    docker-compose

    # Media
    yt-dlp

    # System
    reflector
    timeshift
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
    trap 'rm -rf "$tmp_dir"' RETURN
    git clone https://aur.archlinux.org/yay.git "$tmp_dir/yay"
    (cd "$tmp_dir/yay" && makepkg -si --noconfirm)
    log_ok "yay installed"
}

# ─────────────────────────────────────────────────────────────────────────────
# AUR Packages
# ─────────────────────────────────────────────────────────────────────────────

AUR_PACKAGES=(
    gruvbox-plus-icon-theme
    libation
)

install_aur_packages() {
    log_info "Installing AUR packages..."
    yay -S --needed --noconfirm "${AUR_PACKAGES[@]}"
    log_ok "AUR packages installed"
}

# ─────────────────────────────────────────────────────────────────────────────
# Gruvbox GTK Theme
# ─────────────────────────────────────────────────────────────────────────────

install_gruvbox_gtk_theme() {
    local theme_dir="$HOME/.themes/Gruvbox-Orange-Dark-Medium"

    if [[ -d "$theme_dir/gtk-3.0" ]]; then
        log_ok "Gruvbox GTK theme already installed"
        return
    fi

    log_info "Installing Gruvbox GTK theme..."
    local tmp_dir
    tmp_dir=$(mktemp -d)
    trap 'rm -rf "$tmp_dir"' RETURN
    git clone https://github.com/Fausto-Korpsvart/Gruvbox-GTK-Theme "$tmp_dir/Gruvbox-GTK-Theme"

    # Install dark medium variant with orange accent
    # -l flag automatically symlinks GTK4 CSS into ~/.config/gtk-4.0/
    (cd "$tmp_dir/Gruvbox-GTK-Theme/themes" && ./install.sh --tweaks medium -c dark -t orange -l)

    log_ok "Gruvbox GTK theme installed"
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

    # Apply patches (only on fresh clone, before config.h is copied)
    if [[ ! -f "$dwm_dir/.patched" ]]; then
        local patches=(
            "https://dwm.suckless.org/patches/pertag/dwm-pertag-20200914-61bb8b2.diff"
            "https://dwm.suckless.org/patches/swallow/dwm-swallow-6.3.diff"
        )

        (
            cd "$dwm_dir"
            for url in "${patches[@]}"; do
                local name
                name=$(basename "$url")
                local patch_file
                patch_file=$(mktemp)

                log_info "Downloading $name..."
                if ! curl -fsSL "$url" -o "$patch_file"; then
                    log_info "Failed to download $name, skipping"
                    rm -f "$patch_file"
                    continue
                fi

                if git apply --check "$patch_file" 2>/dev/null; then
                    log_info "Applying $name..."
                    git apply "$patch_file"
                else
                    log_info "$name has conflicts, skipping"
                fi
                rm -f "$patch_file"
            done
        )

        touch "$dwm_dir/.patched"
    fi

    # Copy custom config.h if available in repo
    if [[ -f "$CONFIG_DIR/dwm/config.h" ]]; then
        cp "$CONFIG_DIR/dwm/config.h" "$dwm_dir/config.h"
        log_info "Applied custom dwm config.h"
    fi

    # Copy scripts if available
    if [[ -d "$CONFIG_DIR/dwm/scripts" ]]; then
        mkdir -p "$dwm_dir/scripts"
        cp "$CONFIG_DIR/dwm/scripts/"* "$dwm_dir/scripts/"
        chmod +x "$dwm_dir/scripts/"*
        log_info "Deployed dwm scripts"
    fi

    # Compile and install
    # Only use sudo for install, not compile, to avoid root-owned files
    log_info "Compiling dwm..."
    (cd "$dwm_dir" && make clean && sudo make install)

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
    # Only use sudo for install, not compile, to avoid root-owned files
    log_info "Compiling slstatus..."
    (cd "$slstatus_dir" && make clean && sudo make install)

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

    # Always write autostart.sh so re-runs stay in sync with setup.sh
    local autostart="$HOME/.config/dwm/autostart.sh"
    log_info "Writing autostart.sh..."
    mkdir -p "$HOME/.config/dwm"
    cat > "$autostart" << 'EOF'
#!/bin/sh
slstatus &
dunst &
lxsession &
picom -b &
feh --randomize --bg-fill ~/Pictures/wallpapers/* &
nm-applet --indicator &
exec dwm
EOF
    chmod +x "$autostart"

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

    # Bluetooth
    if ! systemctl is-enabled bluetooth &>/dev/null; then
        sudo systemctl enable bluetooth
        log_info "Enabled bluetooth"
    fi

    # Docker
    if ! systemctl is-enabled docker &>/dev/null; then
        sudo systemctl enable docker
        log_info "Enabled docker"
    fi
    if ! groups "$USER" | grep -q docker; then
        sudo usermod -aG docker "$USER"
        log_info "Added $USER to docker group"
    fi

    # Pipewire (user service - enabled by default on Arch, but just in case)
    if ! systemctl --user is-enabled pipewire &>/dev/null 2>&1; then
        systemctl --user enable pipewire pipewire-pulse
        log_info "Enabled pipewire"
    fi

    log_ok "Services enabled"
}

# ─────────────────────────────────────────────────────────────────────────────
# Cursor Theme
# ─────────────────────────────────────────────────────────────────────────────

install_cursor_theme() {
    local icon_dir="$HOME/.local/share/icons"

    if [[ -d "$icon_dir/phinger-cursors-light" ]]; then
        log_ok "Cursor theme already installed (user)"
    else
        log_info "Installing phinger-cursors..."
        mkdir -p "$icon_dir"
        curl -fsSL https://github.com/phisch/phinger-cursors/releases/latest/download/phinger-cursors-variants.tar.bz2 | tar xfj - -C "$icon_dir"
        log_ok "Cursor theme installed"
    fi

    # Also copy to system icons so LightDM/slick-greeter can use it
    if [[ ! -d /usr/share/icons/phinger-cursors-light ]]; then
        if [[ ! -d "$icon_dir/phinger-cursors-light" ]]; then
            log_err "phinger-cursors-light not found in $icon_dir, skipping system copy"
        else
            log_info "Copying cursor theme to system icons for LightDM..."
            sudo cp -r "$icon_dir/phinger-cursors-light" /usr/share/icons/
            log_ok "Cursor theme copied to /usr/share/icons/"
        fi
    fi
}

# ─────────────────────────────────────────────────────────────────────────────
# Slick Greeter
# ─────────────────────────────────────────────────────────────────────────────

configure_slick_greeter() {
    log_info "Configuring slick-greeter..."

    # Copy background wallpaper to system-accessible path
    local bg_src="$SCRIPT_DIR/wallpapers/macos-sequoia.jpg"
    if [[ -f "$bg_src" ]]; then
        sudo mkdir -p /usr/share/backgrounds
        sudo cp "$bg_src" /usr/share/backgrounds/macos-sequoia.jpg
        log_info "Copied background to /usr/share/backgrounds/"
    else
        log_info "macos-sequoia.jpg not found in wallpapers/, skipping background"
    fi

    # Deploy slick-greeter config
    if [[ -f "$CONFIG_DIR/lightdm/slick-greeter.conf" ]]; then
        sudo cp "$CONFIG_DIR/lightdm/slick-greeter.conf" /etc/lightdm/slick-greeter.conf
        log_info "Deployed slick-greeter.conf"
    fi

    log_ok "slick-greeter configured"
}

# ─────────────────────────────────────────────────────────────────────────────
# Xresources
# ─────────────────────────────────────────────────────────────────────────────

setup_xresources() {
    log_info "Setting up Xresources..."

    if [[ -f "$CONFIG_DIR/Xresources" ]]; then
        cp "$CONFIG_DIR/Xresources" "$HOME/.Xresources"
        log_info "Deployed .Xresources"
    fi

    log_ok "Xresources configured"
}

# ─────────────────────────────────────────────────────────────────────────────
# XDG User Directories
# ─────────────────────────────────────────────────────────────────────────────

setup_xdg_dirs() {
    log_info "Setting up XDG user directories..."
    xdg-user-dirs-update
    log_ok "XDG user directories created"
}

# ─────────────────────────────────────────────────────────────────────────────
# Wallpapers
# ─────────────────────────────────────────────────────────────────────────────

setup_wallpapers() {
    local wall_dir="$HOME/Pictures/wallpapers"

    log_info "Deploying wallpapers..."
    mkdir -p "$wall_dir"
    cp "$SCRIPT_DIR/wallpapers/"* "$wall_dir/"
    log_ok "Wallpapers deployed to $wall_dir"
}

# ─────────────────────────────────────────────────────────────────────────────
# Dotfiles
# ─────────────────────────────────────────────────────────────────────────────

deploy_configs() {
    log_info "Deploying config files..."

    # Config files to copy: source (in repo) -> destination
    local -A configs=(
        ["$CONFIG_DIR/emacs/init.el"]="$HOME/.config/emacs/init.el"
["$CONFIG_DIR/picom/picom.conf"]="$HOME/.config/picom/picom.conf"
        ["$CONFIG_DIR/rofi/config.rasi"]="$HOME/.config/rofi/config.rasi"
        ["$CONFIG_DIR/rofi/gruvbox-material.rasi"]="$HOME/.config/rofi/gruvbox-material.rasi"
        ["$CONFIG_DIR/kitty/kitty.conf"]="$HOME/.config/kitty/kitty.conf"
        ["$CONFIG_DIR/kitty/current-theme.conf"]="$HOME/.config/kitty/current-theme.conf"
        ["$CONFIG_DIR/xarchiver/xarchiverrc"]="$HOME/.config/xarchiver/xarchiverrc"
        ["$CONFIG_DIR/bashrc"]="$HOME/.bashrc"
        ["$CONFIG_DIR/dunst/dunstrc"]="$HOME/.config/dunst/dunstrc"
        ["$CONFIG_DIR/gtk-3.0/settings.ini"]="$HOME/.config/gtk-3.0/settings.ini"
        ["$CONFIG_DIR/gtk-3.0/gtk.css"]="$HOME/.config/gtk-3.0/gtk.css"
        ["$CONFIG_DIR/gtk-4.0/settings.ini"]="$HOME/.config/gtk-4.0/settings.ini"
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
    install_aur_packages
    install_gruvbox_gtk_theme
    install_dwm
    install_slstatus
    setup_dwm_session
    setup_xdg_dirs
    deploy_configs
    install_cursor_theme
    setup_xresources
    setup_wallpapers
    configure_lightdm
    configure_slick_greeter
    enable_services
    log_ok "Setup complete!"
}

main "$@"
