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
LOCALREPO="$ROOT/localrepo"
LOCALREPO_NAME="nexus"

for dep in mkarchiso repo-add; do
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
            partition rawfs mount welcomeq license keyboard locale \
            networkcfg displaymanager bootloader grub grubcfg efi_bootloader \
            services-openrc services-systemd fstab fsck keyboardq summaryq usersq"
    make -j$(nproc)
    sudo make install
    cd "$ROOT"
    rm -rf "$TMPDIR"
}

# Install build dependencies FIRST (including Calamares build deps + pacman-contrib for repo-add)
echo "==> [1/3] Installing build dependencies"
sudo pacman -S --needed --noconfirm \
    archiso base-devel git pacman-contrib \
    squashfs-tools dosfstools libisoburn \
    arch-install-scripts \
    jsoncpp \
    cmake extra-cmake-modules qt6-base qt6-declarative qt6-svg \
    kconfig kcoreaddons kcrash ki18n kparts kpmcore kservice kwidgetsaddons \
    libpwquality mkinitcpio-openswap networkmanager polkit-qt6 python \
    qt6-tools yaml-cpp boost boost-libs \
    vulkan-headers

# Reinstall cmake after jsoncpp update to fix libjsoncpp.so.26 linkage
sudo pacman -S --needed --noconfirm --overwrite '*' cmake

# Update library cache
sudo ldconfig

# makepkg comes from base-devel
command -v makepkg >/dev/null 2>&1 || { echo "HATA: makepkg not found after base-devel install" >&2; exit 1; }

# Prepare a clean local pacman repo directory for the nexus-* packages.
# mkarchiso cannot "see" packages that only sit in /var/cache/pacman/pkg -
# it needs a real repo database (repo-add) that pacman.conf points to.
echo "==> Preparing local pacman repo at $LOCALREPO"
rm -rf "$LOCALREPO"
mkdir -p "$LOCALREPO"

# Build local Nexus packages (branding, wallpapers, keyring, calamares config)
echo "==> Building local Nexus packages"
for pkg in nexus-branding nexus-wallpapers nexus-keyring nexus-calamares; do
    if [ -d "$ROOT/localpkgs/$pkg" ]; then
        echo "  building $pkg"
        ( cd "$ROOT/localpkgs/$pkg" && makepkg -sf --noconfirm --skippgpcheck )
        cp -f "$ROOT/localpkgs/$pkg"/*.pkg.tar.zst "$LOCALREPO/"
    fi
done

# Build the repo database so pacman/mkarchiso can resolve nexus-* as install targets
echo "==> Building local repo database ($LOCALREPO_NAME.db.tar.gz)"
( cd "$LOCALREPO" && repo-add --new "$LOCALREPO_NAME.db.tar.gz" ./*.pkg.tar.zst )

# Make sure archiso/pacman.conf actually references our local repo.
# Insert it at the TOP so it's checked before core/extra/multilib.
PACMAN_CONF="$ROOT/archiso/pacman.conf"
if [ -f "$PACMAN_CONF" ] && ! grep -q "^\[$LOCALREPO_NAME\]" "$PACMAN_CONF"; then
    echo "==> Registering [$LOCALREPO_NAME] repo in $PACMAN_CONF"
    TMP_CONF="$(mktemp)"
    {
        echo "[$LOCALREPO_NAME]"
        echo "SigLevel = Optional TrustAll"
        echo "Server = file://$LOCALREPO"
        echo
        cat "$PACMAN_CONF"
    } > "$TMP_CONF"
    mv "$TMP_CONF" "$PACMAN_CONF"
elif [ ! -f "$PACMAN_CONF" ]; then
    echo "HATA: $PACMAN_CONF bulunamadı, [nexus] reposu eklenemedi." >&2
    exit 1
else
    echo "==> [$LOCALREPO_NAME] repo zaten pacman.conf içinde, atlanıyor"
fi

# Build Calamares from source AFTER deps are installed
# Always build from source to ensure Nexus branding and avoid CachyOS package
echo "==> [2/3] Building Calamares from source"
build_calamares

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