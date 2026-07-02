# Changelog

All notable changes to this project are documented here.

Format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/). No
version tags yet — everything lives under Unreleased. History older than this
file is in `git log`.

## [Unreleased]

### Changed

- **setup.sh is now distro-agnostic** — supports Arch, Debian/Ubuntu, and
  Fedora. Distro family auto-detected from `/etc/os-release` (`ID`/`ID_LIKE`);
  unsupported distros fail fast in preflight.
  - All package operations go through `pkg_update` / `pkg_install` /
    `pkg_installed` / `pkg_remove` wrappers (pacman / apt-get / dnf).
  - Per-distro package lists: `PACKAGES_ARCH`, `PACKAGES_DEBIAN`,
    `PACKAGES_FEDORA`. Packages with no repo equivalent on a distro are
    listed in `UNAVAILABLE_*` and skipped with a warning.
  - yay and AUR packages are Arch-only, skipped with a warning elsewhere.
  - Microcode package names mapped per distro (`intel-ucode` /
    `intel-microcode` / `microcode_ucode`; AMD on Fedora via
    `linux-firmware`).
  - Idempotency unchanged: same sentinels and existence checks; apt-get and
    dnf skip installed packages natively (pacman keeps `--needed`).
  - Install list is pre-filtered through `pkg_available` — a package name
    missing on a given release (e.g. `fastfetch` on Ubuntu 24.04) is warned
    about and skipped instead of aborting the whole transaction.
  - Package lists verified in containers: Arch (host pacman), Debian 13,
    Ubuntu 24.04, and Fedora latest all resolve clean.
- kitty font switched from JetBrainsMono Nerd Font to Maple Mono Normal NL NF.
- README updated for multi-distro support.

### Fixed

- picom: blur disabled for the slop selection overlay (blur made screenshot
  region picking unusable) and for Chrome/Brave, matching the existing
  Firefox exclusion.

### Added

- Screenshot keys documented in the rofi keybindings cheatsheet
  (`Super+s` region, `Super+Shift+s` fullscreen).
- This changelog.
