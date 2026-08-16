#!/usr/bin/env bash
# Builds all Nexus fork packages in localpkgs/ into a local repository and
# optionally wires them into the ISO build (netinstall.yaml + pacman.conf).
#
# Run on the build host (requires pacman/makepkg, NOT in the sandbox):
#   ./build-nexus-repo.sh               # build + create local repo
#   ./build-nexus-repo.sh --apply-swap  # also swap cachyos-* -> nexus-* in the profile
#
# The swap should only be applied once every nexus-* package actually builds.
#
# Notes:
#  - nexus-settings pulls the CachyOS-Settings git tag over a *signed* source;
#    import the upstream PGP keys first (gpg --recv-keys E8B9AA39F054E30E8290D492C3C4820857F654FE B1B70BB1CD56047DEF31DE2EB62C3D10C54D5DA9).
#  - nexus-calamares compiles Calamares from source and needs the Qt6/KDE
#    build dependencies; this is the slowest package in the set.
set -e
set -o pipefail

cd "$(dirname "$0")"
ROOT="$(pwd)"
REPO="$ROOT/localpkgs/repo"
PKGS="$ROOT/localpkgs"
APPLY_SWAP="${1:---build-only}"

[ "$APPLY_SWAP" = "--apply-swap" ] && APPLY_SWAP=1 || APPLY_SWAP=0

# Nexus package signing. Every package and the repository database are signed
# with the Nexus master key (see localpkgs/nexus-keyring). makepkg --sign and
# repo-add -s read GPGKEY + GNUPGHOME; the key was generated with an empty
# passphrase so signing is non-interactive. Override via NEXUS_GPGKEY /
# NEXUS_GNUPGHOME if the key is restored somewhere else.
export GPGKEY="${NEXUS_GPGKEY:-D7E66A16EB101E21ADC20D6315F9E61760540D3C}"
export GNUPGHOME="${NEXUS_GNUPGHOME:-$ROOT/localpkgs/nexus-keyring/gnupg}"

# nexus-settings fetches the CachyOS-Settings git tag over a *signed* source.
# makepkg verifies that signature with $GNUPGHOME (the Nexus keyring above),
# NOT with the default ~/.gnupg, so the upstream signing keys must live here
# or the PGP check fails with "bilinmeyen kamu anahtari". The same applies to
# nexus-zsh-config, nexus-kernel-manager, nexus-packageinstaller (Vladislav)
# and nexus-handheld (Peter, Vladislav, Eric).
# Fetch each upstream signing key into $GNUPGHOME and surface failures instead
# of swallowing them: a missing key silently breaks the PGP verification of the
# signed sources below, so each failure is reported loudly.
_UPSTREAM_KEYS=(
    E8B9AA39F054E30E8290D492C3C4820857F654FE  # Peter Jung (CachyOS)
    B1B70BB1CD56047DEF31DE2EB62C3D10C54D5DA9  # Vladislav Nepogodin
    E18447AC260021D31F3FF6C4C8A2A4774B8B63C4  # (nexus-packageinstaller / handheld)
)
for _key in "${_UPSTREAM_KEYS[@]}"; do
    gpg --batch --no-tty --recv-keys "$_key" >/dev/null 2>&1 \
        || echo "UYARI: PGP anahtari alinamadi: $_key (signed source dogrulamasi basarisiz olabilir)" >&2
done

mkdir -p "$REPO"
: > "$REPO/.build-nexus-repo.log"

echo "==> Building Nexus fork packages"
# Explicit build order: nexus-wallpapers must be built before nexus-kde-settings,
# which depends on it. Package directories not listed here are still built,
# after the listed ones.
BUILD_ORDER=(
    nexus-wallpapers
    nexus-kde-settings
)
PACKAGE_LIST=("${BUILD_ORDER[@]}")
for pkgdir in "$PKGS"/*/; do
    name="$(basename "$pkgdir")"
    [ "$name" = "repo" ] && continue
    [ -f "$pkgdir/PKGBUILD" ] || continue
    case " ${BUILD_ORDER[*]} " in *" $name "*) continue ;; esac
    PACKAGE_LIST+=("$name")
done
for name in "${PACKAGE_LIST[@]}"; do
    pkgdir="$PKGS/$name"
    echo "  building $name"
    # Retry transient network failures (large git clones). Stream to the
    # terminal too, so makepkg sudo prompts stay visible. Flags:
    #   -d  skip dependency checks. build-nexus-iso.sh step [2/5] already
    #       installs every build/makedepends; runtime depends between fork
    #       packages (nexus-kde-settings -> nexus-wallpapers) are not on the
    #       host and must not be synced via pacman.
    #   -f  force rebuild (do not skip already-built packages).
    #   --sign  sign the package with the Nexus master key (GPGKEY/GNUPGHOME above).
    built=0
    for attempt in 1 2 3; do
        if ( cd "$pkgdir" && makepkg -df --sign ) 2>&1 | tee -a "$REPO/.build-nexus-repo.log"; then
            built=1
            break
        fi
        [ "$attempt" -lt 3 ] && { echo "  $name denemesi $attempt/3 basarisiz oldu, tekrar deneniyor..."; sleep 5; }
    done
    if [ "$built" -eq 0 ]; then
        echo "ERROR: build of $name failed (cikti yukarida)" >&2
        exit 1
    fi
done

PKGFILES="$(find "$PKGS" -maxdepth 2 -name '*.pkg.tar.zst' 2>/dev/null)"
if [ -z "$PKGFILES" ]; then
    echo "ERROR: no packages were built" >&2
    exit 1
fi

echo "==> Populating local repository"
find "$PKGS" -mindepth 2 -maxdepth 2 -name '*.pkg.tar.zst' ! -path "$PKGS/repo/*" -print0 2>/dev/null | xargs -0 -I{} cp -f {} "$REPO/"
find "$PKGS" -mindepth 2 -maxdepth 2 -name '*.pkg.tar.zst.sig' ! -path "$PKGS/repo/*" -print0 2>/dev/null | xargs -0 -I{} cp -f {} "$REPO/"
# -s signs the repository database with the Nexus master key.
repo-add -q -s -k "$GPGKEY" "$REPO/nexus.db.tar.zst" "$REPO/"*.pkg.tar.zst

echo "==> Local repo ready: $REPO"
ls -la "$REPO"/*.pkg.tar.zst

if [ "$APPLY_SWAP" = 1 ]; then
    echo "==> Swapping cachyos-* package references -> nexus-*"
    # One shared sed program for every file that lists packages: the
    # netinstall groups (online installs) and the build package lists
    # (offline installs bake the packages into the live squashfs).
    SED_OPTS=(
        -e 's/\bcachyos-keyring\b/nexus-keyring/g'
        -e 's/\bcachyos-hooks\b/nexus-hooks/g'
        -e 's/\bcachyos-v3-mirrorlist\b/nexus-v3-mirrorlist/g'
        -e 's/\bcachyos-v4-mirrorlist\b/nexus-v4-mirrorlist/g'
        -e 's/\bcachyos-mirrorlist\b/nexus-mirrorlist/g'
        -e 's/\bcachyos-wallpapers\b/nexus-wallpapers/g'
        -e 's/\bcachyos-kde-settings\b/nexus-kde-settings/g'
        -e 's/\bcachyos-settings\b/nexus-settings/g'
        -e 's/\bcachyos-micro-settings\b/nexus-micro-settings/g'
        -e 's/\bcachyos-fish-config\b/nexus-fish-config/g'
        -e 's/\bcachyos-zsh-config\b/nexus-zsh-config/g'
        -e 's/\bcachyos-kernel-manager\b/nexus-kernel-manager/g'
        -e 's/\bcachyos-packageinstaller\b/nexus-packageinstaller/g'
        -e 's/\bcachyos-handheld\b/nexus-handheld/g'
        -e 's/\bcachyos-mangowc-dms\b/nexus-mangowc-dms/g'
        -e 's/\bcachyos-rate-mirrors\b/nexus-rate-mirrors/g'
        -e 's/\bcachyos-calamares-next\b/nexus-calamares/g'
    )

    NETINSTALL="archiso/airootfs/usr/share/nexus-calamares/modules/netinstall.yaml"
    N="$(grep -c "cachyos-" "$NETINSTALL" || true)"
    sed -i "${SED_OPTS[@]}" "$NETINSTALL"
    echo "  netinstall.yaml: replaced $N cachyos-* references (remaining: $(grep -c 'cachyos-' "$NETINSTALL" || true))"

    for PKG_FILE in archiso/packages.x86_64 archiso/packages_desktop.x86_64 archiso/packages_minimal.x86_64; do
        [ -f "$PKG_FILE" ] || continue
        N="$(grep -c "cachyos-" "$PKG_FILE" || true)"
        sed -i "${SED_OPTS[@]}" "$PKG_FILE"
        echo "  $PKG_FILE: replaced $N cachyos-* references (remaining: $(grep -c 'cachyos-' "$PKG_FILE" || true))"
    done
    echo "  Remaining cachyos-* references are the CachyOS kernel packages"
    echo "  (linux-cachyos*, chwd, deckify, cli-installer-new) and are kept as-is."

    # Keep the online installer script in sync with the swapped package names.
    sed -i \
        -e 's/cachyos-calamares-next/nexus-calamares/g' \
        -e 's/cachyos-keyring/nexus-keyring/g' \
        -e 's/pacman-key --populate archlinux cachyos/pacman-key --populate archlinux nexus/' \
        archiso/airootfs/usr/local/bin/calamares-online.sh

    # [nexus] belongs in the LIVE/installed pacman.conf: the (swapped)
    # netinstall.yaml resolves nexus-* packages from it during the install.
    LIVE_PACMAN_CONF="archiso/airootfs/etc/pacman.conf"
    if ! grep -q "^\[nexus\]" "$LIVE_PACMAN_CONF"; then
        cat >> "$LIVE_PACMAN_CONF" <<EOF

[nexus]
SigLevel = Optional TrustAll
# Nexus packages are published as GitHub Release assets (no dedicated mirror
# yet). pacman appends the db filename (nexus.db) to this URL; GitHub serves
# the latest release's assets here and follows the redirect transparently.
# TrustAll matches the [cachyos] section; the Nexus master key is populated
# into the live keyring from /usr/share/pacman/keyrings (calamares-online.sh).
Server = https://github.com/nexuslinux/nexuslinux/releases/latest/download/
EOF
        echo "  appended [nexus] repo to $LIVE_PACMAN_CONF"
    else
        echo "  [nexus] repo already present in $LIVE_PACMAN_CONF"
    fi

    # The BUILD pacman.conf needs [nexus] too: the swapped packages*.x86_64
    # list nexus-* packages that only this repo provides. Point it at the
    # LOCAL repo built above and skip signature checks (SigLevel=Never), so no
    # Nexus key is needed in pacstrap's archlinux-only keyring during the
    # build. The repo never reaches the installed system: the live/installed
    # [nexus] (airootfs pacman.conf) uses GitHub + the populated keyring.
    BUILD_PACMAN_CONF="archiso/pacman.conf"
    if grep -q "^\[nexus\]" "$BUILD_PACMAN_CONF"; then
        sed -i '/^\[nexus\]/,$d' "$BUILD_PACMAN_CONF"
    fi
    cat >> "$BUILD_PACMAN_CONF" <<EOF

[nexus]
SigLevel = Never
Server = file://$ROOT/localpkgs/repo
EOF
    echo "  appended [nexus] (file://$ROOT/localpkgs/repo, SigLevel=Never) to build pacman.conf ($BUILD_PACMAN_CONF)"

    # Ship the Nexus keyring into the airootfs so `pacman-key --populate
    # archlinux nexus` (calamares-online.sh) works on the live ISO and the
    # nexus-keyring package stays consistent with the profile.
    KEYRINGS_DIR="archiso/airootfs/usr/share/pacman/keyrings"
    mkdir -p "$KEYRINGS_DIR"
    cp -f localpkgs/nexus-keyring/nexus.gpg \
          localpkgs/nexus-keyring/nexus-trusted \
          localpkgs/nexus-keyring/nexus-revoked "$KEYRINGS_DIR/"
    echo "  shipped Nexus keyring files to $KEYRINGS_DIR"
    echo "NOTE: OFFLINE installs bake the swapped nexus-* packages into the"
    echo "      live squashfs (packages*.x86_64 + build [nexus] file:// local"
    echo "      repo), so they work without a network."
    echo "      ONLINE installs resolve nexus-* from GitHub Releases"
    echo "      (https://github.com/nexuslinux/nexuslinux/releases/latest/download/)."
    echo "      Publish the local repo there first with:"
    echo "          ./release-nexus.sh repo"
    echo "      Otherwise ONLINE installs will not find the nexus-* packages."
    echo "      Packages are signed by the Nexus master key (nexus-keyring:"
    echo "      pacman-key --lsign-key). SigLevel=Optional TrustAll for [nexus]"
    echo "      (the key must be in the keyring; populated from the airootfs)."
else
    echo "==> Dry run (no swap). Re-run with --apply-swap to wire into the ISO build."
fi
