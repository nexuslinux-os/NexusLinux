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
# or the PGP check fails with "bilinmeyen kamu anahtari".
gpg --batch --no-tty --recv-keys \
    E8B9AA39F054E30E8290D492C3C4820857F654FE \
    B1B70BB1CD56047DEF31DE2EB62C3D10C54D5DA9 2>/dev/null || true
gpg --batch --no-tty --list-keys C3C4820857F654FE >/dev/null 2>&1 \
    || echo "UYARI: CachyOS imza anahtari Nexus keyring'e alinamadi (nexus-settings PGP dogrulamasi basarisiz olabilir)" >&2

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
    N="$(grep -c "cachyos-" archiso/airootfs/etc/calamares/modules/netinstall.yaml || true)"
    sed -i \
        -e 's/\bcachyos-keyring\b/nexus-keyring/g' \
        -e 's/\bcachyos-hooks\b/nexus-hooks/g' \
        -e 's/\bcachyos-v3-mirrorlist\b/nexus-v3-mirrorlist/g' \
        -e 's/\bcachyos-v4-mirrorlist\b/nexus-v4-mirrorlist/g' \
        -e 's/\bcachyos-mirrorlist\b/nexus-mirrorlist/g' \
        -e 's/\bcachyos-wallpapers\b/nexus-wallpapers/g' \
        -e 's/\bcachyos-kde-settings\b/nexus-kde-settings/g' \
        -e 's/\bcachyos-settings\b/nexus-settings/g' \
        -e 's/\bcachyos-fish-config\b/nexus-fish-config/g' \
        -e 's/\bcachyos-calamares-next\b/nexus-calamares/g' \
        archiso/airootfs/etc/calamares/modules/netinstall.yaml
    echo "  netinstall.yaml: replaced $N cachyos-* references (remaining: $(grep -c 'cachyos-' archiso/airootfs/etc/calamares/modules/netinstall.yaml || true))"
    echo "  Remaining cachyos-* references are packages not yet forked"
    echo "  (themes, kernel-manager, deckify, ...) and are kept for now."

    # Keep the online installer script in sync with the swapped package names.
    sed -i \
        -e 's/cachyos-calamares-next/nexus-calamares/g' \
        -e 's/cachyos-keyring/nexus-keyring/g' \
        -e 's/pacman-key --populate archlinux cachyos/pacman-key --populate archlinux nexus/' \
        archiso/airootfs/usr/local/bin/calamares-online.sh

    PACMAN_CONF="archiso/pacman.conf"
    if ! grep -q "^\[nexus\]" "$PACMAN_CONF"; then
        cat >> "$PACMAN_CONF" <<EOF

[nexus]
SigLevel = Optional DatabaseOptional
Server = file://$ROOT/localpkgs/repo
EOF
        echo "  appended [nexus] repo to $PACMAN_CONF"
    else
        echo "  [nexus] repo already present in $PACMAN_CONF"
    fi
    echo "NOTE: [nexus] verifies packages signed by the Nexus master key"
    echo "      (nexus-keyring: pacman-key --lsign-key). SigLevel=TrustAll is gone."
else
    echo "==> Dry run (no swap). Re-run with --apply-swap to wire into the ISO build."
fi
