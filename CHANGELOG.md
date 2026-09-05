# Nexus Linux Changelog

## 2026-09-05

### Rust Integration (Major Feature)

* **8 New CLI Tools in Rust** (`nexus-rust-tools` meta-package)
  - `nexus-info` — System information display (JSON/pretty output)
  - `nexus-version` — Version information tool (JSON/short/full)
  - `nexus-check` — System health check (disk, memory, network, services, security)
  - `nexus-hardware` — Hardware detection (CPU, RAM, GPU, disks, network, USB, PCI)
  - `nexus-micro` — Micro settings (zram, hostname, services)
  - `nexus-installer` — Package installer backend (alpm bindings)
  - `nexus-theme` — Wallpaper/theme utilities (generate, apply, list)
  - `nexus-build` — Build helpers (verify, validate, gen pkglist, create ISO)

* **Rust Workspace Infrastructure**
  - Cargo workspace with 8 crates in `localpkgs/rust-workspace/`
  - Cargo.lock with 214 crates locked
  - `nexus-rust-tools` meta-package builds all 8 binaries
  - Added to both `packages_desktop.x86_64` and `packages_minimal.x86_64`

### 2026-09-04

### Major Changes

* **Pure Arch Linux Base**: Completely removed all CachyOS dependencies and repositories
  - Removed `[cachyos]` repository from all pacman.conf files
  - Deleted entire `localpkgs/` directory (all CachyOS-derived fork packages)
  - Removed CachyOS keyring files, mirrorlists, and hooks
  - Removed `cachy-chroot`, `cachyos-cli-installer-new`, `cachyos-ananicy-rules` packages
  - Updated all documentation to reflect pure Arch base

* **Calamares Installer**: Now built from source (v3.3.12)
  - Added build dependencies: cmake, qt6, kconfig, kcoreaddons, kcrash, ki18n, kparts, kpmcore, kservice, kwidgetsaddons, libpwquality, polkit-qt6, python, yaml-cpp, boost, jsoncpp
  - Disabled unnecessary modules for lighter ISO
  - Installs before ISO build via build script

* **DE Selection**: Reduced to 3 options
  - KDE Plasma (recommended)
  - GNOME
  - COSMIC
  - Removed: Cinnamon, Budgie, MATE, Xfce, LXQt, LXDE, Hyprland, MangoWM, Sway, i3, Openbox, phosh, Niri

* **File Manager & Terminal**: Switched to GNOME stack
  - `dolphin` → `nautilus`
  - `konsole` → `ptyxis`

### Hardware Support (Debian-style out-of-the-box)

* **Firmware**: Added comprehensive firmware packages
  - `linux-firmware-qlogic`, `linux-firmware-bnx2x`, `linux-firmware-liquidio`
  - `linux-firmware-nfp`, `linux-firmware-qcom`, `linux-firmware-whence`

* **GPU Drivers**: Modern Intel/AMD support
  - `intel-media-driver`, `vulkan-intel`, `vulkan-radeon`
  - `libva-intel-driver`, `libva-mesa-driver`, `mesa-vdpau`

* **Network**: WiFi/Ethernet/Bluetooth
  - `r8168`, `broadcom-wl-dkms`, `rtl8821cu-dkms`, `rtl8852be-dkms`, `mt7921-firmware`
  - `bluez`, `bluez-utils`, `bluez-plugins`, `bluez-hid2hci`

* **Printing & Scanning**: Full CUPS stack
  - `cups`, `cups-filters`, `cups-pdf`, `ghostscript`, `gsfonts`
  - `system-config-printer`, `simple-scan`, `sane`, `sane-airscan`

* **Network Discovery**: Avahi/mDNS
  - `avahi`, `nss-mdns`

### Build System

* **Simplified build script** (`build-nexus-iso.sh`)
  - Reordered: install deps → build calamares → build ISO
  - Install jsoncpp before cmake, reinstall cmake after jsoncpp update
  - Run `ldconfig` to fix library linkage
  - Removed PGP signing, local repo management, fork swap logic

* **GRUB Theme**: New Nexus-branded theme
  - `/boot/grub/themes/nexus/` with dark blue gradient background
  - Custom colors: #1793d1 (accent), #1a1a2e (background)
  - Font fallback generation via `grub-mkfont`

### Security

* **ClamAV**: Antivirus included by default
  - `clamav` daemon + `clamtk` GUI

### Rust Tooling Infrastructure

* **Rust Workspace** (`localpkgs/rust-workspace/`)
  - 8 crates in Cargo workspace
  - Cargo.lock with 214 crates locked
  - `nexus-rust-tools` meta-package builds all 8 binaries
  - Added to both `packages_desktop.x86_64` and `packages_minimal.x86_64`

* **Build System Updates**
  - `cargo fetch --locked --target x86_64-unknown-linux-gnu`
  - `cargo build --release --frozen --workspace`
  - `nexus-rust-tools` meta-package builds all 8 binaries

### Documentation

* **README.md**: Rewritten with banner, Rust tools, updated package list
* **CONTRIBUTING.md**: Updated for Arch-based workflow
* **SECURITY.md**: Removed CachyOS references
* **GITHUB_ISSUES.md**: 42 issues catalog from code review
* **create_github_issues.py**: Script to auto-create GitHub issues
- **.vscode**: Complete VS Code config (tasks, debug, snippets, keybindings)
- **.gitattributes** + **.github/linguist**: Rust language detection for GitHub
- **.github/linguist**: Linguist override for Rust detection

---

## 2026-09-01 (Initial Fork)

* Forked from CachyOS live ISO
* Initial rebranding to "Nexus Linux"
* KDE Plasma desktop with Calamares installer
* Nexus package repository structure (`localpkgs/`)