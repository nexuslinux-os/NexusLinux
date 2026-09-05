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
CALAMARES_VERSION="3.3.12"
CALAMARES_PKGBUILD_DIR="$ROOT/.calamares-pkgbuild"

for dep in mkarchiso repo-add makepkg; do
    command -v "$dep" >/dev/null 2>&1 || { echo "HATA: eksik bağımlılık: $dep" >&2; exit 1; }
done

# Install build dependencies FIRST (including Calamares build deps + pacman-contrib for repo-add)
echo "==> [1/4] Installing build dependencies"
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
sudo ldconfig

command -v makepkg >/dev/null 2>&1 || { echo "HATA: makepkg not found after base-devel install" >&2; exit 1; }

# Prepare a clean local pacman repo directory.
# mkarchiso cannot "see" packages that only sit in /var/cache/pacman/pkg or on
# the host filesystem - it needs a real repo database (repo-add) that
# pacman.conf points to, containing ACTUAL .pkg.tar.zst files.
echo "==> Preparing local pacman repo at $LOCALREPO"
rm -rf "$LOCALREPO"
mkdir -p "$LOCALREPO"

# ---------------------------------------------------------------------------
# Build Calamares AS A PACKAGE (not "sudo make install" onto the host).
# mkarchiso builds the ISO in its own clean chroot and only knows about
# packages available via pacman repos - it does not care what is installed
# on the host machine. So Calamares must become a real .pkg.tar.zst that we
# add to our local repo, exactly like nexus-branding etc.
# ---------------------------------------------------------------------------
build_calamares_package() {
    echo "==> [2/4] Packaging Calamares $CALAMARES_VERSION"
    rm -rf "$CALAMARES_PKGBUILD_DIR"
    mkdir -p "$CALAMARES_PKGBUILD_DIR"
    cat > "$CALAMARES_PKGBUILD_DIR/PKGBUILD" <<EOF
pkgname=calamares
pkgver=${CALAMARES_VERSION}
pkgrel=1
pkgdesc="Distribution-independent installer framework (Nexus trimmed build)"
arch=('x86_64')
url="https://calamares.io"
license=('GPL3')
depends=('qt6-base' 'qt6-declarative' 'qt6-svg' 'kconfig' 'kcoreaddons' 'kcrash'
         'ki18n' 'kparts' 'kpmcore' 'kservice' 'kwidgetsaddons' 'libpwquality'
         'polkit-qt6' 'yaml-cpp' 'boost-libs' 'python')
makedepends=('git' 'cmake' 'extra-cmake-modules' 'qt6-tools' 'boost' 'jsoncpp')
source=("git+https://github.com/calamares/calamares.git#tag=v\${pkgver}")
sha256sums=('SKIP')


build() {
  cd "\$srcdir/calamares"
  mkdir -p build && cd build
  cmake .. \\
    -DCMAKE_INSTALL_PREFIX=/usr \\
    -DCMAKE_BUILD_TYPE=Release \\
    -DINSTALL_CONFIG=ON \\
    -DSKIP_MODULES="webview interactiveterminal initramfs initramfscfg \\
        partition rawfs mount welcomeq license keyboard users usersq locale \\
        networkcfg displaymanager bootloader grub grubcfg efi_bootloader \\
        services-openrc services-systemd fstab fsck keyboardq summaryq"
  make
}


package() {
  cd "\$srcdir/calamares/build"
  make DESTDIR="\$pkgdir" install
}
EOF
    ( cd "$CALAMARES_PKGBUILD_DIR" && makepkg -sf --noconfirm --skippgpcheck )
    cp -f "$CALAMARES_PKGBUILD_DIR"/calamares-*.pkg.tar.zst "$LOCALREPO/"
}

if ls "$LOCALREPO"/calamares-*.pkg.tar.zst >/dev/null 2>&1; then
    echo "==> [2/4] Calamares paketi zaten localrepo'da, atlanıyor"
else
    build_calamares_package
fi

# Build local Nexus packages (branding, wallpapers, keyring, calamares config)
echo "==> [3/4] Building local Nexus packages"
for pkg in nexus-branding nexus-wallpapers nexus-keyring nexus-calamares; do
    if [ -d "$ROOT/localpkgs/$pkg" ]; then
        echo "  building $pkg"
        ( cd "$ROOT/localpkgs/$pkg" && makepkg -sf --noconfirm --skippgpcheck )
        cp -f "$ROOT/localpkgs/$pkg"/*.pkg.tar.zst "$LOCALREPO/"
    fi
done

# Build the repo database so pacman/mkarchiso can resolve these as install targets
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

echo "==> [4/4] Building ISO (profile: $PROFILE)"

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