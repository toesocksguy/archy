#!/usr/bin/env bash
#
# Arch Linux Environment Setup Script
#
# Sets up a DWM-based desktop environment with Gruvbox Material Dark theming
# on a fresh Arch Linux install.
#
# PRECONDITIONS:
#   - Run as a regular user with sudo access (not root)
#   - pacman and base system available
#   - Network connection active
#
# IDEMPOTENCY:
#   - Safe to re-run. Most steps are guarded by existence checks.
#   - autostart.sh is always overwritten to stay in sync with this script.
#   - Wallpapers and config files are always redeployed on re-run.
#
# ORDERING:
#   - Packages must be installed before anything that depends on them.
#   - yay must be installed before AUR packages.
#   - install_cursor_theme must run before configure_slick_greeter so the
#     cursor is in /usr/share/icons/ when LightDM reads its config.
#   - configure_lightdm must run before enable_services so LightDM starts
#     with the correct greeter and session already configured.
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
    iw

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
# Removes packages that conflict with our desired stack before installation.
# Checks each package individually to avoid pacman failing on missing packages.
# Pulseaudio must be removed before pipewire-pulse — they own the same socket.
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

# Full system upgrade before installing packages to avoid partial upgrade issues.
# Arch does not support partial upgrades — skipping this risks broken dependencies.
update_system() {
    log_info "Updating system..."
    sudo pacman -Syu --noconfirm
    log_ok "System updated"
}

# Installs all packages in PACKAGES. Calls remove_conflicting first to clear
# anything that would cause a conflict. --needed skips already-installed packages,
# making this safe to re-run.
install_packages() {
    log_info "Installing packages..."
    remove_conflicting
    sudo pacman -S --needed --noconfirm "${PACKAGES[@]}"
    log_ok "Packages installed"
}

# ─────────────────────────────────────────────────────────────────────────────
# AUR Helper
# ─────────────────────────────────────────────────────────────────────────────

# Installs yay AUR helper from source. Skips if already installed.
# Uses a subshell for the cd so a build failure doesn't strand the parent shell.
# trap ensures the tmp dir is cleaned up even if makepkg fails.
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

# Installs AUR packages via yay. Skips already-installed packages with --needed.
# Requires yay to be installed first.
install_aur_packages() {
    log_info "Installing AUR packages..."
    yay -S --needed --noconfirm "${AUR_PACKAGES[@]}"
    log_ok "AUR packages installed"
}

# ─────────────────────────────────────────────────────────────────────────────
# Gruvbox GTK Theme
# ─────────────────────────────────────────────────────────────────────────────

# Clones and installs the Gruvbox GTK theme from source. Skips if already installed.
# --tweaks medium -c dark -t orange -l installs the dark/orange/medium variant and
# symlinks GTK4 CSS into ~/.config/gtk-4.0/. sassc must be installed or the GTK3
# theme is silently skipped by the upstream install script.
# trap ensures tmp dir is cleaned up even if the install script fails.
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

# Shared setup for suckless tools: clone, patch, copy config.h.
# Usage: install_suckless_tool <name> <repo_url> [patch_url...]
# Callers are responsible for any pre-compile steps and the compile itself.
# Patches are only applied once — .patched sentinel prevents re-patching on
# re-runs, which would cause conflicts against already-patched source.
install_suckless_tool() {
    local name=$1
    local url=$2
    shift 2
    local patches=("$@")
    local tool_dir="$HOME/.config/$name"

    log_info "Setting up $name..."
    mkdir -p "$tool_dir"

    # Clone if directory is empty
    if [[ -z "$(ls -A "$tool_dir" 2>/dev/null)" ]]; then
        log_info "Cloning $name..."
        git clone "$url" "$tool_dir"
    fi

    # Apply patches only on fresh clone — sentinel prevents re-patching
    if [[ ${#patches[@]} -gt 0 && ! -f "$tool_dir/.patched" ]]; then
        (
            cd "$tool_dir"
            for patch_url in "${patches[@]}"; do
                local patch_name patch_file
                patch_name=$(basename "$patch_url")
                patch_file=$(mktemp)

                log_info "Downloading $patch_name..."
                if ! curl -fsSL "$patch_url" -o "$patch_file"; then
                    log_info "Failed to download $patch_name, skipping"
                    rm -f "$patch_file"
                    continue
                fi

                # --check before --apply: a failed check means the patch has conflicts
                # against already-patched source. Non-fatal — log and skip rather than abort,
                # since partial patching is better than no dwm.
                if git apply --check "$patch_file" 2>/dev/null; then
                    log_info "Applying $patch_name..."
                    git apply "$patch_file"
                else
                    log_info "$patch_name has conflicts, skipping"
                fi
                rm -f "$patch_file"
            done
        )
        touch "$tool_dir/.patched"
    fi

    # Copy custom config.h if available in repo
    if [[ -f "$CONFIG_DIR/$name/config.h" ]]; then
        cp "$CONFIG_DIR/$name/config.h" "$tool_dir/config.h"
        log_info "Applied custom $name config.h"
    fi
}

# Installs dwm. Applies pertag and swallow patches, deploys scripts, and compiles.
install_dwm() {
    install_suckless_tool "dwm" "https://git.suckless.org/dwm" \
        "https://dwm.suckless.org/patches/pertag/dwm-pertag-20200914-61bb8b2.diff" \
        "https://dwm.suckless.org/patches/swallow/dwm-swallow-6.3.diff"

    # Copy scripts (dwm-specific — slstatus has no scripts dir)
    if [[ -d "$CONFIG_DIR/dwm/scripts" ]]; then
        mkdir -p "$HOME/.config/dwm/scripts"
        cp "$CONFIG_DIR/dwm/scripts/"* "$HOME/.config/dwm/scripts/"
        chmod +x "$HOME/.config/dwm/scripts/"*
        log_info "Deployed dwm scripts"
    fi

    # Compile and install — user compiles, sudo only for install to avoid root-owned files
    log_info "Compiling dwm..."
    (cd "$HOME/.config/dwm" && make clean && sudo make install)
    log_ok "dwm installed"
}

# Installs slstatus. Injects the host's wireless interface name before compiling.
install_slstatus() {
    install_suckless_tool "slstatus" "https://git.suckless.org/slstatus"

    # Inject the host's actual wireless interface name before compiling —
    # baked into the binary since slstatus is compiled C, not a script.
    local iface
    iface=$(iw dev | awk '/Interface/{print $2; exit}')
    if [[ -n "$iface" ]]; then
        sed -i "s/wlan0/$iface/" "$HOME/.config/slstatus/config.h"
    fi

    # Compile and install — user compiles, sudo only for install to avoid root-owned files
    log_info "Compiling slstatus..."
    (cd "$HOME/.config/slstatus" && make clean && sudo make install)
    log_ok "slstatus installed"
}

# ─────────────────────────────────────────────────────────────────────────────
# Desktop Session
# ─────────────────────────────────────────────────────────────────────────────

# Creates the dwm.desktop session file for LightDM and writes autostart.sh.
# dwm.desktop is only written once — it references $HOME which doesn't change.
# autostart.sh is always overwritten so re-runs stay in sync with this script.
# Uses $HOME instead of ~ in the .desktop Exec field — .desktop files do not
# expand tilde.
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

# Configures LightDM to use slick-greeter and dwm as the default session.
# Edits /etc/lightdm/lightdm.conf in place with sed. Guards against a missing
# [Seat:*] section, which is commented out by default on a fresh Arch install —
# sed would silently no-op without the guard.
configure_lightdm() {
    log_info "Configuring LightDM..."

    local conf="/etc/lightdm/lightdm.conf"

    if ! grep -q "^\[Seat:\*\]" "$conf" 2>/dev/null; then
        log_err "[Seat:*] section not found in $conf — LightDM not configured"
        return 1
    fi

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

# Enables system and user services. Each service is guarded by is-enabled so
# re-runs don't re-enable already-enabled services.
# Pipewire is a user service — enabled without sudo via systemctl --user.
# Docker group membership requires logout to take effect.
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

# Downloads and installs phinger-cursors-light to two locations:
#   ~/.local/share/icons/  — for GTK/X11 apps during the user session
#   /usr/share/icons/      — for LightDM/slick-greeter at the login screen
# The system copy is guarded against a missing user install in case the
# download failed earlier in the same run.
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

# Copies the LightDM background to /usr/share/backgrounds/ and deploys
# slick-greeter.conf to /etc/lightdm/. Both paths must be system-accessible —
# LightDM runs as its own user and cannot read from $HOME.
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

# Deploys .Xresources to $HOME. Skips silently if not present in the repo.
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

# Creates standard XDG user directories (~/Documents, ~/Downloads, etc.).
# Safe to re-run — xdg-user-dirs-update is idempotent.
setup_xdg_dirs() {
    log_info "Setting up XDG user directories..."
    xdg-user-dirs-update
    log_ok "XDG user directories created"
}

# ─────────────────────────────────────────────────────────────────────────────
# Wallpapers
# ─────────────────────────────────────────────────────────────────────────────

# Copies all wallpapers from the repo to ~/Pictures/wallpapers/.
# Always redeployed on re-run so the live set stays in sync with the repo.
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

# Copies all config files from the repo to their destinations under $HOME.
# Always redeployed on re-run — no existence checks, latest repo state wins.
# Skips individual files that are not present in the repo without failing.
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
