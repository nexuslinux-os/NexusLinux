# Nexus Linux - Codex Configuration

## Project: Nexus Linux
**Type:** Pure Arch-based Linux distribution
**Target:** Web-app focused, lightweight, security-oriented desktop OS

## Architecture
- **Base:** Pure Arch Linux (core/extra/multilib only)
- **Desktop:** KDE Plasma (primary), GNOME, COSMIC
- **Installer:** Calamares (built from source v3.3.12)
- **Package Format:** .pkg.tar.zst via makepkg
- **Repo Management:** Local pacman repo with repo-add

## Build Pipeline
```
1. Install deps (archiso, base-devel, calamares deps, pacman-contrib)
2. Build Calamares as package → localrepo/
3. Build local Nexus packages → localrepo/
4. Create repo database (repo-add)
5. Register local [nexus] repo in pacman.conf (priority)
5. Build ISO via mkarchiso
```

## Repository Structure
```
nexus-live/
├── archiso/                 # archiso profile
│   ├── airootfs/           # Live system overlay
│   ├── packages*.x86_64    # Package lists
│   ├── pacman.conf         # With [nexus] repo at top
│   └── buildiso.sh         # Upstream build driver
├── localpkgs/              # Nexus packages (makepkg)
│   ├── nexus-branding/     # os-release, lsb-release
│   ├── nexus-wallpapers/   # Default wallpaper
│   ├── nexus-keyring/      # Signing keys + install script
│   └── nexus-calamares/    # Calamares modules, branding, configs
├── localrepo/              # Built packages + repo DB
├── .calamares-pkgbuild/    # Calamares package build (temp)
├── build-nexus-iso.sh      # Main build script
└── buildiso.sh             # Upstream driver
```

## Key Features
- **Pure Arch base** - No CachyOS, Chaotic-AUR, or third-party repos
- **Calamares from source** - Packaged as .pkg.tar.zst, not host-installed
- **Local pacman repo** - Proper repo-add database for mkarchiso
- **Calamares modules skipped:** users, usersq, locale, keyboard, etc.
- **Nexus branding** - GRUB, Plymouth, KDE Plasma, Calamares

## Package Lists
All packages from official Arch repos only:
- `packages.x86_64` - Base + all profiles
- `packages_desktop.x86_64` - Full desktop
- `packages_minimal.x86_64` - Minimal install

## Testing
```bash
# Quick package build test
cd localpkgs/nexus-branding && makepkg -sf --noconfirm --skippgpcheck

# Full ISO build
./build-nexus-iso.sh desktop
```

## Dependencies
### Build deps (auto-installed)
archiso, base-devel, git, pacman-contrib, cmake, qt6-*, kconfig, kcoreaddons, ki18n, kparts, kpmcore, kservice, kwidgetsaddons, libpwquality, polkit-qt6, yaml-cpp, boost, jsoncpp, vulkan-headers

### Runtime packages (in package lists)
linux-zen, plasma-desktop, nautilus, ptyxis, clamav/clamtk, bluez, cups, intel-media-driver, vulkan-*, and comprehensive firmware/drivers

## Security
- ClamAV + ClamTK included
- AppArmor/SELinux ready
- Hardened kernel options
- No AUR packages in ISO