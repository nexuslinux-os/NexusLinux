#!/usr/bin/env bash
# One-shot Nexus ISO build: keyring keys -> fork packages -> local repo ->
# profile swap -> ISO build.
#
# Usage (run from this repo, path without spaces):
#   ./build-nexus-iso.sh [profile]
#
# Default profile: "desktop". Requires makepkg + mkarchiso on the host.
set -e

cd "$(dirname "$0")"
ROOT="$(pwd)"
PROFILE="${1:-desktop}"

for dep in makepkg mkarchiso repo-add gpg; do
    command -v "$dep" >/dev/null 2>&1 || { echo "HATA: eksik bağımlılık: $dep" >&2; exit 1; }
done

echo "==> [1/4] Upstream PGP keys (nexus-settings signed source)"
gpg --recv-keys E8B9AA39F054E30E8290D492C3C4820857F654FE B1B70BB1CD56047DEF31DE2EB62C3D10C54D5DA9 2>/dev/null || true

echo "==> [2/5] Installing build dependencies (tek seferlik sudo sifresi istenecek)"
# All depends/makedepends of the fork packages, so makepkg never needs syncdeps.
sudo pacman -S --needed --noconfirm \
    base-devel git meson cargo clang lld llvm \
    glib2 gtk3 pciutils procps-ng libusb \
    boost boost-libs ckbcomp cryptsetup dmidecode gptfdisk hwinfo \
    kconfig kcoreaddons kcrash ki18n kparts kpmcore kservice kwidgetsaddons \
    libpwquality mkinitcpio-openswap networkmanager polkit-qt6 python \
    qt6-declarative qt6-svg rsync solid squashfs-tools upower yaml-cpp \
    qt6-imageformats python-toml \
    cmake doxygen extra-cmake-modules ninja \
    python-jsonschema python-pyaml python-unidecode qt6-tools \
    zram-generator ananicy-cpp cachyos-ananicy-rules inxi systemd iw wireless-regdb \
    bat expac eza fastfetch fish fish-autopair fish-pure-prompt fisher fzf \
    pkgfile tealdeer ttf-fantasque-nerd

echo "==> [3/5] Building Nexus fork packages + local repo"
./build-nexus-repo.sh

# The fork swap is opt-in: it rewrites netinstall.yaml to install nexus-*
# packages from a [nexus] repo whose Server=file:// path only exists on the
# build host. On the live ISO that repo is unreachable, so enabling the swap
# before the Nexus repos are published breaks the live installer. Keep the
# swap OFF (default) and install the upstream cachyos-* packages instead.
if [ -n "${NEXUS_SWAP:-}" ]; then
    echo "==> [4/5] Wiring fork packages into the ISO profile (swap) [NEXUS_SWAP set]"
    ./build-nexus-repo.sh --apply-swap
else
    echo "==> [4/5] Skipping fork swap (upstream cachyos-* packages in the ISO)."
    echo "        Set NEXUS_SWAP=1 to apply the nexus-* swap."
fi

echo "==> [5/5] Building ISO (profile: $PROFILE)"

# cachyos-calamares-next owns /etc/calamares/modules/netinstall.yaml and
# packagechooser_desktop.conf, so any copies in the profile airootfs make
# pacstrap abort with a file conflict. The Nexus versions live at the
# non-conflicting staging path /usr/share/nexus-calamares/modules and are
# installed by customize_airootfs.sh / the calamares launchers. Relocate any
# stray copies back there so the build can never trip over them again.
CALAMARES_CONFLICT="$ROOT/archiso/airootfs/etc/calamares/modules"
CALAMARES_STAGE="$ROOT/archiso/airootfs/usr/share/nexus-calamares/modules"
for _f in netinstall.yaml packagechooser_desktop.conf; do
    if [ -f "$CALAMARES_CONFLICT/$_f" ]; then
        echo "    -> relocating $_f to $CALAMARES_STAGE"
        mv -f "$CALAMARES_CONFLICT/$_f" "$CALAMARES_STAGE/$_f"
    fi
done

./buildiso.sh -p "$PROFILE" -v 2>&1 | tee "$ROOT/build.log"

echo "==> Bitti. Sonuçlar:"
echo "    - build log:  $ROOT/build.log"
echo "    - ISO:        $ROOT/out/<profil>/*.iso  (yalnizca ham ISO; .img/.sig/checksum/pkgs.txt uretilmez)"
