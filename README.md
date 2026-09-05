<p align="center">
  <img src="readme-banner.svg" alt="Nexus Linux Banner" width="100%">
</p>

# Nexus Linux

A Linux distribution built on **pure Arch Linux** with `archiso`. Nexus Linux ships the KDE Plasma desktop, the Calamares installer (offline and online), and its own repository of packages with Nexus branding. Includes **8 Rust-based CLI tools** for system management, hardware detection, health checks, and build automation.

This repository contains the live ISO build configuration and the source for the Nexus packages.

## Repository layout

```
.
├── archiso/                    # airootfs overlay, pacman.conf, package lists
├── localpkgs/                  # Nexus packages (built into a local repo)
│   ├── nexus-branding/         # os-release, lsb-release
│   ├── nexus-wallpapers/       # Default wallpapers
│   ├── nexus-keyring/          # Package signing keys
│   ├── nexus-calamares/        # Calamares modules, branding, config
│   ├── nexus-kde-settings/     # KDE Plasma defaults
│   ├── nexus-rust-tools/       # 8 Rust CLI tools (meta-package)
│   └── rust-workspace/         # Cargo workspace (8 crates)
├── .vscode/                    # VS Code config (tasks, debug, snippets)
├── .github/                    # GitHub Linguist config
├── build-nexus-iso.sh          # one-shot ISO build (+ release artifacts)
├── build-nexus-repo.sh         # package build + profile wiring
├── release-nexus.sh            # publish repo/ISO to GitHub Releases
├── buildiso.sh                 # upstream ISO build driver
├── util-iso.sh                 # profile/version helpers
├── CHANGELOG.md                # Version history
├── CONTRIBUTING.md             # Contribution guide
├── SECURITY.md                 # Security policy
├── GITHUB_ISSUES.md            # 42 issues catalog from code review
├── create_github_issues.py     # Auto-create GitHub issues
└── readme-banner.svg           # Banner image
```

## Packages (`localpkgs/`)

### Core Nexus Packages

| Package | Purpose |
| --- | --- |
| `nexus-branding` | os-release, lsb-release, /usr/lib/os-release |
| `nexus-wallpapers` | Default wallpapers + per-desktop defaults |
| `nexus-keyring` | Nexus package signing keys (`nexus.gpg`, `nexus-trusted`, `nexus-revoked`) |
| `nexus-calamares` | Calamares modules, branding, config (Calamares app built separately) |
| `nexus-kde-settings` | Default KDE Plasma settings (kdeglobals, kwinrc, plasmarc, plasmarc) |
| `nexus-rust-tools` | **Meta-package: 8 Rust CLI tools** (see below) |

### Rust CLI Tools (`nexus-rust-tools` meta-package)

| Binary | Purpose |
| --- | --- |
| `nexus-info` | System information display (JSON/pretty output) |
| `nexus-version` | Version info tool (JSON/short/full) |
| `nexus-check` | System health check (disk, memory, network, services, security) |
| `nexus-hardware` | Hardware detection (CPU, RAM, GPU, disks, network, USB, PCI) |
| `nexus-micro` | Micro settings (zram, hostname, services) |
| `nexus-installer` | Package installer backend (alpm bindings) |
| `nexus-theme` | Wallpaper/theme utilities (generate, apply, list) |
| `nexus-build` | Build helpers (verify, validate, gen pkglist, create ISO) |

### Rust Workspace (`localpkgs/rust-workspace/`)

Cargo workspace with 8 crates:
- `nexus-info`, `nexus-version`, `nexus-check`, `nexus-hardware`
- `nexus-micro`, `nexus-installer-backend`, `nexus-theme`, `nexus-build-helpers`

Built as `nexus-rust-tools` meta-package via `cargo build --release --frozen --workspace`

## Building the ISO

Build on an Arch-based host (needs `pacman`/`makepkg`; this cannot run in a sandbox).

### Requirements

```bash
sudo pacman -S archiso --needed
```

### One-shot build

```bash
cd /path/to/nexus-live
./build-nexus-iso.sh                 # default profile: "desktop minimal"
./build-nexus-iso.sh "desktop"       # single profile
```

This script:

1. Installs build dependencies (archiso, base-devel, git, Calamares deps, Rust toolchain)
2. Builds Calamares from source (v3.3.12) as a package
3. Builds all local Nexus packages via `makepkg` and populates `localrepo/`
4. Creates local pacman repo database (`repo-add`)
4. Registers `[nexus]` repo in `pacman.conf` (priority over core/extra)
5. Builds ISO via `mkarchiso` and writes release artifacts to `out/<profile>/`
   (`.sig`, `SHA256SUMS`, `.img`, `pkgs.txt`)

### Manual steps

```bash
# build packages + create local repo
./build-nexus-repo.sh

# wire packages into the ISO profile (registers local repo in pacman.conf)
./build-nexus-repo.sh --apply-swap

# build the ISO
./buildiso.sh -p "desktop minimal" -v
```

## Live desktop installer

On the live desktop Calamares opens directly (autostart entry), instead of a welcome/hello app:

- `/usr/local/bin/launch-calamares.sh` — picks the online installer when a network is available, otherwise the offline one
- `/usr/local/bin/calamares-online.sh` — refreshes the keyring, applies Nexus branding, launches Calamares
- `/usr/local/bin/calamares-offline.sh` — network-free variant using the Calamares shipped on the ISO

## DE Selection

Only 3 desktop environments available in Calamares:
- **KDE Plasma** (recommended, default)
- **GNOME**
- **COSMIC**

## Hardware Support (Debian-style out-of-the-box)

- **Firmware**: `linux-firmware-*` (qlogic, bnx2x, liquidio, nfp, qcom, whence)
- **GPU**: `intel-media-driver`, `vulkan-intel`, `vulkan-radeon`, `libva-*`, `mesa-vdpau`
- **Network**: `r8168`, `broadcom-wl-dkms`, `rtl8821cu-dkms`, `rtl8852be-dkms`, `mt7921-firmware`
- **Bluetooth**: `bluez`, `bluez-utils`, `bluez-plugins`, `bluez-hid2hci`
- **Printing/Scanning**: `cups`, `cups-filters`, `cups-pdf`, `ghostscript`, `gsfonts`, `system-config-printer`, `simple-scan`, `sane`, `sane-airscan`
- **Avahi/mDNS**: `avahi`, `nss-mdns`

## Security

* **ClamAV**: Antivirus included by default (`clamav` daemon + `clamtk` GUI)
* **GRUB Theme**: Nexus-branded with dark blue gradient
* **Calamares**: Built from source (v3.3.12), minimal modules

## Signing key

The master signing key is generated by `localpkgs/nexus-keyring/gen-nexus-keyring.sh`:

- Fingerprint: `F4C57604C90E90CD6AB3633F2AA4846E14CBE512`
- Identity: `Nexus Linux Packaging <nexus@nexuslinux.org>`

**Back up the private key** under `localpkgs/nexus-keyring/gnupg/`.

## Repository signing

Every Nexus package and the `nexus.db` repository database are signed with the master key:

- `build-nexus-repo.sh` builds with `makepkg --sign` and adds the database with `repo-add -s -k` using `GPGKEY`/`GNUPGHOME`
- The `nexus-keyring` package's install script runs `pacman-key --add` and `pacman-key --lsign-key F4C57604C90E90CD6AB3633F2AA4846E14CBE512`
- The `[nexus]` repo uses `SigLevel = Required DatabaseOptional` (packages must be signed by the Nexus master key)
- `release-nexus.sh repo` publishes `nexus.db(.sig)`, `nexus.files(.sig)` and every `.pkg.tar.zst(.sig)` as release assets

Rebuild the keyring after any change with:

```bash
cd localpkgs/nexus-keyring && GNUPGHOME="$PWD/gnupg" GPGKEY=F4C57604C90E90CD6AB3633F2AA4846E14CBE512 makepkg -f --sign
```

## CI/CD & Development

* **.vscode/**: Complete VS Code config (tasks, debug, snippets, keybindings)
* **.github/linguist**: GitHub Linguist config for Rust detection
* **.gitattributes**: Linguist overrides for language detection
* **.vscode/extensions.json**: Recommended extensions (shellcheck, yaml, gitlens, docker)
* **GITHUB_ISSUES.md**: 42 issues catalog from code review
* **create_github_issues.py**: Script to auto-create GitHub issues
* **.github/linguist**: Linguist override for Rust detection

## Known notes

- The installed system's `pacman.conf` is generated from `archiso/pacman.conf` + `pacman-more.conf` by shellprocess scripts
- Nexus uses its own repo section names (`[nexus]`)
- Pure Arch base — no CachyOS, Chaotic-AUR, or third-party repos