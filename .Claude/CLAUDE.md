# Nexus Linux - Claude Instructions

## Project Overview
Nexus Linux is a Pure Arch-based Linux distribution with:
- KDE Plasma desktop (primary), GNOME, COSMIC as options
- Calamares installer (built from source, packaged as .pkg.tar.zst)
- Local pacman repository for Nexus-branded packages
- Pure Arch base (no CachyOS remnants)

## Build System
- Script: `./build-nexus-iso.sh [profile]`
- Profiles: `desktop` (default), `minimal`
- 4-stage build: deps → Calamares pkg → local pkgs → ISO
- Local pacman repo at `localrepo/` with `repo-add` database

## Key Directories
- `archiso/` - archiso profile (airootfs, packages, grub, syslinux)
- `localpkgs/` - Nexus packages (branding, wallpapers, keyring, calamares config)
- `localrepo/` - Built packages + repo database
- `.calamares-pkgbuild/` - Calamares package build directory (temp)

## Package Management
- Pure Arch repos only (core, extra, multilib)
- No CachyOS, Chaotic-AUR, or other third-party repos
- Nexus packages: nexus-branding, nexus-wallpapers, nexus-keyring, nexus-calamares
- Calamares built from source v3.3.12, packaged as .pkg.tar.zst

## Development Guidelines
- Keep packages in official Arch repos where possible
- Nexus packages only for branding/config
- Calamares built from source, not installed on host
- Local repo (`localrepo/`) used by mkarchiso via pacman.conf

## Common Commands
```bash
# Build ISO
./build-nexus-iso.sh desktop

# Build single package
cd localpkgs/nexus-branding && makepkg -sf --noconfirm --skippgpcheck

# Clean build
rm -rf build out localrepo .calamares-pkgbuild
./build-nexus-iso.sh desktop
```

## Architecture
- Pure Arch base (no CachyOS)
- Calamares v3.3.12 built from source, packaged
- GRUB theme with Nexus branding
- Plymouth splash with Nexus branding
- KDE Plasma with Nexus look-and-feel theme
- ClamAV + ClamTK included