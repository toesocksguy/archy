# Archy

An idempotent setup script for a dwm-based Arch Linux desktop environment.

## What It Does

- Updates the system
- Installs packages via pacman
- Installs yay (AUR helper)
- Compiles and installs dwm from suckless.org
- Compiles and installs slstatus from suckless.org
- Configures LightDM with slick-greeter
- Sets up dwm desktop session (autostart.sh)
- Deploys config files (bashrc, emacs, ghostty, picom, rofi, dwm, slstatus, Xresources)
- Installs phinger-cursors cursor theme
- Creates wallpaper directory
- Enables system services (NetworkManager, LightDM, pipewire)

## Usage

```bash
chmod +x setup.sh
./setup.sh
```

## Packages Installed

### Core
- base-devel, git

### X11
- xorg-server, xorg-xinit, xorg-xrandr, xorg-xsetroot

### dwm Dependencies
- libx11, libxft, libxinerama, fontconfig, freetype2

### Applications
- emacs, ghostty, picom, rofi, thunar, firefox

### Display Manager
- lightdm, lightdm-slick-greeter

### Utilities
- fzf, ripgrep, feh, mise, xclip, maim, slop, dmenu

### Fonts
- ttf-jetbrains-mono-nerd

### Audio
- pipewire, pipewire-pulse, pavucontrol

### Network
- networkmanager, network-manager-applet

## Troubleshooting Notes

Issues encountered during development and testing.

### Package Conflicts: pipewire-pulse vs pulseaudio

**Problem:** `pacman -S --noconfirm` fails when pipewire-pulse conflicts with pulseaudio.

**Error:**
```
pipewire-pulse and pulseaudio are in conflict. Remove pulseaudio? [y/N]
error: unresolvable package conflicts detected
```

**Solution:** The script removes conflicting packages (pulseaudio, pulseaudio-bluetooth) before installing new packages.

### Outdated Package Database

**Problem:** Installing packages fails on a fresh Arch install that hasn't been updated.

**Solution:** Run `pacman -Syu` before installing packages.

### LightDM Fails to Start

**Problem:** After reboot, LightDM fails with "Failed to start Light Display Manager".

**Error in `/var/log/lightdm/lightdm.log`:**
```
Failed to find session configuration lightdm-gtk-greeter
Failed to create greeter session
Failed to start seat: seat0
```

**Cause:** LightDM defaults to lightdm-gtk-greeter, but we installed lightdm-slick-greeter.

**Solution:** Configure the greeter in `/etc/lightdm/lightdm.conf`:
```bash
sudo sed -i '/^\[Seat:\*\]/a greeter-session=lightdm-slick-greeter' /etc/lightdm/lightdm.conf
```

### "Failed to Start Session" at Login

**Problem:** LightDM greeter appears, but login fails with "Failed to start session".

**Cause 1:** Missing `network-manager-applet` package (provides `nm-applet` command used in autostart.sh).

**Cause 2:** The `~` in the .desktop Exec path doesn't expand in display managers.

**Cause 3:** No session selector in slick-greeter, and no default session configured.

**Solution:**
1. Install `network-manager-applet`
2. Use `$HOME` or absolute path instead of `~` in .desktop files
3. Set default session in lightdm.conf:
```bash
sudo sed -i '/^\[Seat:\*\]/a user-session=dwm' /etc/lightdm/lightdm.conf
```

### dwm config.h Mismatch

**Problem:** dwm fails to compile with `'refreshrate' undeclared`.

**Cause:** The repo's `config.h` was from an older dwm version. The latest dwm source added a `refreshrate` variable.

**Solution:** Ensure `config/dwm/config.h` stays in sync with the latest dwm source. When new variables are added to `config.def.h` upstream, add them to your `config.h`.

### picom Deprecated Options

**Problem:** picom warns about `blur-background-exclude`.

**Cause:** picom v12+ replaced legacy blur options with a window rules system.

**Solution:** Move blur exclusions into the `rules` section:
```
rules = (
    { match = "class_g = 'Firefox'"; blur-background = false; }
);
```

### QEMU/KVM Video Driver

**Note:** For VMs using QEMU/KVM, you may need to install `xf86-video-qxl` for proper display.

## File Locations

| File | Description |
|------|-------------|
| `/usr/share/xsessions/dwm.desktop` | Desktop session file for LightDM |
| `~/.config/dwm/` | dwm source and config |
| `~/.config/dwm/autostart.sh` | Startup script (slstatus, picom, feh, nm-applet, dwm) |
| `~/.config/slstatus/` | slstatus source and config |
| `~/.bashrc` | Shell configuration |
| `~/.Xresources` | X cursor theme config |
| `~/.local/share/icons/phinger-cursors-light/` | Cursor theme files |
| `~/Pictures/backgrounds/` | Wallpapers for feh |
| `/etc/lightdm/lightdm.conf` | LightDM configuration |

## Status Bar (slstatus)

slstatus is a suckless status monitor that feeds text to dwm's built-in bar. It's a single compiled C binary with no shell overhead.

### Why slstatus?

| Method | Weight | How it works |
|--------|--------|-------------|
| **slstatus** | Lightest | Single C binary, reads system info directly |
| **dwmblocks** | Medium | C binary, but forks shell scripts per block |
| **bash script** | Heaviest | Shell loop, forks subprocesses every iteration |
| **polybar** | Heaviest | C++ with many dependencies, replaces dwm bar entirely |

### Customizing

Edit `~/.config/slstatus/config.h` to configure which components are displayed, then recompile:

```bash
cd ~/.config/slstatus
sudo make clean install
```

### Available Components

Battery, CPU usage/frequency, date/time, disk stats, memory/swap, network speeds, volume, WiFi signal, temperature, uptime, keyboard layout, hostname, kernel version, load average, and custom shell commands.

## Dotfiles

Config files are stored in `config/` and copied to `~/.config/` during setup.

```
config/
├── dwm/
│   └── config.h          # copied into cloned dwm source before compiling
├── slstatus/
│   └── config.h          # copied into cloned slstatus source before compiling
├── emacs/
│   └── init.el
├── ghostty/
│   └── config
├── picom/
│   └── picom.conf
├── rofi/
│   └── config.rasi
├── Xresources            # copied to ~/.Xresources
└── bashrc                # copied to ~/.bashrc
```

To update the repo after making changes to live configs, copy them back:
```bash
cp ~/.config/picom/picom.conf ~/repos/archy/config/picom/picom.conf
```

## TODO

- [ ] Screenshot keybinding in dwm config.h
- [ ] Wallpapers
