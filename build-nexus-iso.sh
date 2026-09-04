#!/usr/bin/env bash
# One-shot Nexus ISO build: pure Arch Linux base -> ISO build.
#
# Usage (run from this repo, path without spaces):
#   ./build-nexus-iso.sh [profile]
#
# Default profile: "desktop". Requires makepkg + mkarchiso on the host.
set -e
set -o pipefail

cd "$(dirname "$0")"
ROOT="$(pwd)"
PROFILE="${1:-desktop}"

for dep in mkarchiso; do
    command -v "$dep" >/dev/null 2>&1 || { echo "HATA: eksik bağımlılık: $dep" >&2; exit 1; }
done

# Build Calamares from source (not in official repos)
build_calamares() {
    echo "==> Building Calamares from source"
    local TMPDIR=$(mktemp -d)
    cd "$TMPDIR"
    git clone --depth 1 --branch v3.3.12 https://github.com/calamares/calamares.git
    cd calamares
    mkdir build && cd build
    cmake .. \
        -DCMAKE_INSTALL_PREFIX=/usr \
        -DCMAKE_BUILD_TYPE=Release \
        -DINSTALL_CONFIG=ON \
        -DSKIP_MODULES="webview interactiveterminal initramfs initramfscfg \
            partition rawfs mount welcomeq license keyboard users locale \
            networkcfg displaymanager bootloader grub grubcfg efi_bootloader \
            services-openrc services-systemd fstab fsck keyboardq summaryq"
    make -j$(nproc)
    sudo make install
    cd "$ROOT"
    rm -rf "$TMPDIR"
}

# Install build dependencies FIRST (including Calamares build deps)
echo "==> [1/3] Installing build dependencies"
sudo pacman -S --needed --noconfirm \
    archiso base-devel git \
    squashfs-tools dosfstools libisoburn \
    arch-install-scripts \
    jsoncpp \
    cmake extra-cmake-modules qt6-base qt6-declarative qt6-svg \
    kconfig kcoreaddons kcrash ki18n kparts kpmcore kservice kwidgetsaddons \
    libpwquality mkinitcpio-openswap networkmanager polkit-qt6 python \
    qt6-tools yaml-cpp boost boost-libs

# Update library cache after installing jsoncpp (fixes cmake libjsoncpp.so.26 error)
sudo ldconfig

# makepkg comes from base-devel
command -v makepkg >/dev/null 2>&1 || { echo "HATA: makepkg not found after base-devel install" >&2; exit 1; }

# Build Calamares from source AFTER deps are installed
# Check if calamares is already installed
if ! pacman -Q calamares >/dev/null 2>&1 && ! command -v calamares >/dev/null 2>&1; then
    echo "==> [2/3] Building Calamares from source"
    build_calamares
else
    echo "==> [2/3] Calamares already installed"
fi

# Clean any stale nexus-* packages from cache (shouldn't exist but safe)
if ls /var/cache/pacman/pkg/nexus-*.pkg.tar.zst >/dev/null 2>&1; then
    sudo rm -f /var/cache/pacman/pkg/nexus-*.pkg.tar.zst \
               /var/cache/pacman/pkg/nexus-*.pkg.tar.zst.sig
    echo "    -> cleaned stale nexus-* from pacman cache"
fi

echo "==> [3/3] Building ISO (profile: $PROFILE)"

# Relocate any stray calamares module copies to staging path
CALAMARES_CONFLICT="$ROOT/archiso/airootfs/etc/calamares/modules"
CALAMARES_STAGE="$ROOT/archiso/airootfs/usr/share/nexus-calamares/modules"
for _f in netinstall.yaml packagechooser_desktop.conf; do
    if [ -f "$CALAMARES_CONFLICT/$_f" ]; then
        echo "    -> relocating $_f to $CALAMARES_STAGE"
        mv -f "$CALAMARES_CONFLICT/$_f" "$CALAMARES_STAGE/$_f"
    fi
done

./buildiso.sh -p "$PROFILE" -v 2>&1 | tee "$ROOT/build.log"

echo "==> Release artifacts (.sig / SHA256SUMS / .img / pkgs.txt)"
ISO_PATH="$(find "$ROOT/out/$PROFILE" -maxdepth 1 -name '*.iso' -print -quit 2>/dev/null)"
if [ -n "$ISO_PATH" ]; then
    ( cd "$(dirname "$ISO_PATH")" && sha256sum "$(basename "$ISO_PATH")" > SHA256SUMS )
    cp -f "$ISO_PATH" "${ISO_PATH%.iso}.img"
    {
        grep -rh '^\s*-\s*[a-z0-9@._+-]' "$ROOT/archiso/airootfs/usr/share/nexus-calamares/modules/netinstall.yaml" | sed 's/^\s*-\s*//'
        cat "$ROOT/archiso/packages.x86_64" 2>/dev/null || true
    } | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' | grep -v '^$' | sort -u > "$ROOT/out/$PROFILE/pkgs.txt"
    echo "    - ISO:        $ISO_PATH"
    echo "    - SHA256:     $ROOT/out/$PROFILE/SHA256SUMS"
    echo "    - USB image:  ${ISO_PATH%.iso}.img (dd to USB)"
    echo "    - Package list: $ROOT/out/$PROFILE/pkgs.txt"
else
    echo "    ERROR: out/$PROFILE/*.iso not found (build may have failed)"
fi

echo "==> Done."
echo "    Build log:  $ROOT/build.log"