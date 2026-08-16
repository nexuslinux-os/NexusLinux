#!/usr/bin/env bash
# One-shot Nexus ISO build: keyring keys -> fork packages -> local repo ->
# profile swap -> ISO build.
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

for dep in makepkg mkarchiso repo-add gpg; do
    command -v "$dep" >/dev/null 2>&1 || { echo "HATA: eksik bağımlılık: $dep" >&2; exit 1; }
done

echo "==> [1/6] Upstream PGP keys (nexus-settings signed source)"
gpg --recv-keys E8B9AA39F054E30E8290D492C3C4820857F654FE B1B70BB1CD56047DEF31DE2EB62C3D10C54D5DA9 2>/dev/null || true

echo "==> [2/6] Installing build dependencies (tek seferlik sudo sifresi istenecek)"
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

echo "==> [3/6] Building Nexus fork packages + local repo"
./build-nexus-repo.sh

# The fork swap wires nexus-* packages into netinstall.yaml (online path),
# swaps them into packages*.x86_64 so the live squashfs bakes them in (offline
# path), and points the [nexus] repo at GitHub Releases (no dedicated mirror).
# Publishing the local repo first makes ONLINE installs work:
#   ./build-nexus-repo.sh && ./release-nexus.sh repo
# Swap is ON by default; set NEXUS_SWAP=0 to keep the upstream cachyos-*
# packages instead. Offline installs need no network (packages are baked in).
if [ "${NEXUS_SWAP:-1}" != "0" ]; then
    echo "==> [4/6] Wiring fork packages into the ISO profile (swap) [NEXUS_SWAP=1]"
    ./build-nexus-repo.sh --apply-swap
else
    echo "==> [4/6] Skipping fork swap (upstream cachyos-* packages in the ISO) [NEXUS_SWAP=0]."
fi

echo "==> [5/6] Building ISO (profile: $PROFILE)"
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

echo "==> [6/6] Release artefaktlari (.sig / SHA256SUMS / .img / pkgs.txt)"
ISO_PATH="$(find "$ROOT/out/$PROFILE" -maxdepth 1 -name '*.iso' -print -quit 2>/dev/null)"
if [ -n "$ISO_PATH" ]; then
    # Sign the ISO with the Nexus master key (same keyring as the packages).
    if [ -f "$ROOT/localpkgs/nexus-keyring/gnupg/secring.gpg" ] || \
       [ -f "$ROOT/localpkgs/nexus-keyring/gnupg/private-keys-v1.d" ]; then
        ( cd "$(dirname "$ISO_PATH")" && \
          GNUPGHOME="$ROOT/localpkgs/nexus-keyring/gnupg" gpg --batch --yes --detach-sign --output "$(basename "$ISO_PATH").sig" "$(basename "$ISO_PATH")" )
    fi
    ( cd "$(dirname "$ISO_PATH")" && sha256sum "$(basename "$ISO_PATH")" > SHA256SUMS )
    cp -f "$ISO_PATH" "${ISO_PATH%.iso}.img"
    {
        grep -rh '^\s*-\s*[a-z0-9@._+-]' "$ROOT/archiso/airootfs/usr/share/nexus-calamares/modules/netinstall.yaml" | sed 's/^\s*-\s*//'
        cat "$ROOT/archiso/packages.x86_64" 2>/dev/null || true
    } | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' | grep -v '^$' | sort -u > "$ROOT/out/$PROFILE/pkgs.txt"
    echo "    - ISO:        $ISO_PATH"
    echo "    - Imza:       $ISO_PATH.sig (Nexus master key)"
    echo "    - SHA256:     $ROOT/out/$PROFILE/SHA256SUMS"
    echo "    - USB imaji:  ${ISO_PATH%.iso}.img (dd ile USB'ye yazilir)"
    echo "    - Paket list: $ROOT/out/$PROFILE/pkgs.txt"
    echo ""
    echo "    GitHub Releases'e yuklemek icin:"
    echo "        ./release-nexus.sh iso $ISO_PATH"
else
    echo "    HATA: out/$PROFILE/*.iso bulunamadi (ISO build hatali olabilir)"
fi

echo "==> Bitti."
echo "    Build log:  $ROOT/build.log"
echo "    Repo yayini: ./release-nexus.sh repo   (once yapilmali)"
