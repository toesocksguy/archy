# Archy

An idempotent setup script for a dwm-based Arch Linux desktop environment.

## What It Does

- Updates the system
- Installs packages via pacman
- Installs yay (AUR helper)
- Compiles and installs dwm from suckless.org
- Configures LightDM with slick-greeter
- Sets up dwm desktop session
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
- emacs, ghostty, picom, rofi, thunar

### Display Manager
- lightdm, lightdm-slick-greeter

### Utilities
- fzf, ripgrep, feh, mise

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

### QEMU/KVM Video Driver

**Note:** For VMs using QEMU/KVM, you may need to install `xf86-video-qxl` for proper display.

## File Locations

| File | Description |
|------|-------------|
| `/usr/share/xsessions/dwm.desktop` | Desktop session file for LightDM |
| `~/.config/dwm/` | dwm source and config |
| `~/.config/dwm/autostart.sh` | Startup script (picom, feh, nm-applet, dwm) |
| `/etc/lightdm/lightdm.conf` | LightDM configuration |

## TODO

- [ ] Status bar configuration
- [ ] Dotfiles management
- [ ] Additional packages (screenshot tools, brightness control, etc.)
