#!/usr/bin/env bash
# Publishes the Nexus package repository and/or an ISO to GitHub Releases.
#
# Nexus has no dedicated package mirror yet, so GitHub Releases doubles as
# the package server: pacman's [nexus] Server points at
#   https://github.com/nexuslinux/nexuslinux/releases/latest/download/
# and every file published here is reachable under that URL (nexus.db,
# nexus.files, *.pkg.tar.zst, ...).
#
# Usage (run on the build host, requires gh + gpg):
#   ./release-nexus.sh repo                          # publish localpkgs/repo as a new release
#   ./release-nexus.sh iso out/desktop/nexus.iso     # sign + checksum + upload an ISO
#
# Repo releases must be created BEFORE the ISO is built with NEXUS_SWAP=1,
# because the live installer resolves nexus-* packages from GitHub.
set -euo pipefail

cd "$(dirname "$0")"
ROOT="$(pwd)"
REPO="$ROOT/localpkgs/repo"
GIT_REPO="${NEXUS_GIT_REPO:-nexuslinux/nexuslinux}"
TAG_PREFIX="${NEXUS_TAG_PREFIX:-nexus-v}"
export GPGKEY="${NEXUS_GPGKEY:-F4C57604C90E90CD6AB3633F2AA4846E14CBE512}"
export GNUPGHOME="${NEXUS_GNUPGHOME:-$ROOT/localpkgs/nexus-keyring/gnupg}"

for dep in gh gpg repo-add; do
    command -v "$dep" >/dev/null 2>&1 || { echo "HATA: eksik bağımlılık: $dep" >&2; exit 1; }
done

# Validate the Nexus master key is usable for signing (non-interactive).
if ! gpg --batch --no-tty --list-keys "$GPGKEY" >/dev/null 2>&1; then
    echo "HATA: Nexus master key ($GPGKEY) $GNUPGHOME icinde bulunamadi" >&2
    echo "      Anahtar geri yuklenmemis olabilir (bkz. localpkgs/nexus-keyring)." >&2
    exit 1
fi

new_tag() {
    local tag
    tag="${TAG_PREFIX}$(date -u +%Y.%m.%d)"
    local i=1
    while gh release view "$tag" --repo "$GIT_REPO" >/dev/null 2>&1; do
        tag="${TAG_PREFIX}$(date -u +%Y.%m.%d)-$i"
        i=$((i + 1))
    done
    echo "$tag"
}

publish_repo() {
    echo "==> Repo yayinlanmasi: $GIT_REPO"
    [ -f "$REPO/nexus.db.tar.zst" ] || { echo "HATA: $REPO/nexus.db.tar.zst yok. Once ./build-nexus-repo.sh calistirin." >&2; exit 1; }

    local work
    work="$(mktemp -d)"
    trap 'rm -rf "$work"' RETURN

    # repo-add produces .db/.files symlinks; GitHub cannot store symlinks, so
    # publish real copies under the exact names pacman will request.
    for name in nexus.db nexus.db.sig nexus.files nexus.files.sig; do
        case "$name" in
            nexus.db)      [ -e "$REPO/nexus.db.tar.zst" ] && cp -f "$REPO/nexus.db.tar.zst"     "$work/nexus.db" ;;
            nexus.db.sig)  [ -e "$REPO/nexus.db.tar.zst.sig" ] && cp -f "$REPO/nexus.db.tar.zst.sig" "$work/nexus.db.sig" ;;
            nexus.files)   [ -e "$REPO/nexus.files.tar.zst" ] && cp -f "$REPO/nexus.files.tar.zst"   "$work/nexus.files" ;;
            nexus.files.sig) [ -e "$REPO/nexus.files.tar.zst.sig" ] && cp -f "$REPO/nexus.files.tar.zst.sig" "$work/nexus.files.sig" ;;
        esac
    done

    local tag notes
    tag="$(new_tag)"
    notes="Nexus repository $(date -u +%Y-%m-%d)

[nexus] repo icin:  Server = https://github.com/$GIT_REPO/releases/latest/download/
Guncelleme:         sudo pacman -Syu"
    echo "==> Yeni release: $tag"
    gh release create "$tag" \
        --repo "$GIT_REPO" \
        --title "Nexus repository $tag" \
        --notes "$notes" \
        "$work/nexus.db" "$work/nexus.db.sig" "$work/nexus.files" "$work/nexus.files.sig" \
        "$REPO"/*.pkg.tar.zst "$REPO"/*.pkg.tar.zst.sig
    echo "==> Bitti: https://github.com/$GIT_REPO/releases/tag/$tag"
    echo "    Sonraki: ./release-nexus.sh iso out/<profil>/<isim>.iso"
}

publish_iso() {
    local iso="$1"
    [ -f "$iso" ] || { echo "HATA: ISO bulunamadi: $iso" >&2; exit 1; }

    local work
    work="$(mktemp -d)"
    trap 'rm -rf "$work"' RETURN

    echo "==> ISO artefaktlari: $iso"

    # Signing + checksums next to the ISO itself.
    gpg --batch --yes --armor --detach-sign --output "$iso.sig" "$iso" 2>/dev/null \
        || gpg --batch --yes --detach-sign --output "$iso.sig" "$iso"
    ( cd "$(dirname "$iso")" && sha256sum "$(basename "$iso")" > "$(dirname "$iso")/SHA256SUMS" )

    # The ISO is already hybrid/dd-able, so no separate .img copy is published.

    # pkgs.txt: profile packages + netinstall selection, sorted, deduped.
    {
        grep -rh '^\s*-\s*[a-z0-9@._+-]' archiso/airootfs/usr/share/nexus-calamares/modules/netinstall.yaml | sed 's/^\s*-\s*//'
        cat archiso/packages.x86_64 2>/dev/null || true
        for f in archiso/*/packages.x86_64; do [ -f "$f" ] && cat "$f"; done 2>/dev/null || true
    } | grep -v '^\s*#' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' | grep -v '^$' | sort -u > "$(dirname "$iso")/pkgs.txt"

    local tag notes
    tag="$(new_tag)"
    notes="Nexus Linux ISO $(date -u +%Y-%m-%d)

    ISO:        $(basename "$iso")
    SHA256:     $(cd "$(dirname "$iso")" && awk '{print $1}' SHA256SUMS)
    USB yazma:  sudo dd if=$(basename "$iso") of=/dev/sdX bs=4M status=progress conv=fsync"
    echo "==> Yeni release: $tag"
    gh release create "$tag" \
        --repo "$GIT_REPO" \
        --title "Nexus Linux $tag" \
        --notes "$notes" \
        "$iso" "$iso.sig" "$(dirname "$iso")/SHA256SUMS" \
        "$(dirname "$iso")/pkgs.txt"
    echo "==> Finished: https://github.com/$GIT_REPO/releases/tag/$tag"
}

case "${1:-}" in
    repo) publish_repo ;;
    iso)  [ $# -ge 2 ] || { echo "Kullanim: $0 iso <dosya.iso>" >&2; exit 1; }; publish_iso "$2" ;;
    *) echo "Kullanim: $0 {repo|iso <dosya.iso>}" >&2; exit 1 ;;
esac
