#!/usr/bin/env bash
# Generates the Nexus package signing keyring files used by the nexus-keyring
# package. Run this ONCE on the build host, then `makepkg -f` the keyring.
#
# The generated secret key is kept on the build host and is the master key for
# signing all Nexus repository packages. Back it up securely (see below);
# losing it means re-signing the whole repository.
#
# The key is protected with a strong passphrase. Provide it non-interactively
# with NEXUS_KEY_PASSPHRASE (e.g. from a secrets manager / CI), or enter it at
# the prompt. An empty passphrase is rejected.
set -e

cd "$(dirname "$0")"

KEY_EMAIL="${NEXUS_KEY_EMAIL:-nexus@nexuslinux.org}"
KEY_NAME="${NEXUS_KEY_NAME:-Nexus Linux Packaging}"
KEY_EXPIRE="${NEXUS_KEY_EXPIRE:-2y}"
GPG_KEYRING="$PWD/gnupg"

# ---- Passphrase handling ---------------------------------------------------
if [ -n "${NEXUS_KEY_PASSPHRASE:-}" ]; then
    PASSPHRASE="$NEXUS_KEY_PASSPHRASE"
    unset NEXUS_KEY_PASSPHRASE
else
    # Interactive prompt (stty so the passphrase is not echoed).
    if [ ! -t 0 ]; then
        echo "ERROR: NEXUS_KEY_PASSPHRASE required (no TTY for prompt)" >&2
        exit 1
    fi
    read -r -s -p "Nexus signing key passphrase (min. 16 chars): " PASSPHRASE; echo
    read -r -s -p "Repeat passphrase: " _confirm; echo
    [ "$PASSPHRASE" = "$_confirm" ] || { echo "ERROR: passphrases do not match" >&2; exit 1; }
    unset _confirm
fi
if [ "${#PASSPHRASE}" -lt 16 ]; then
    if [ -z "$PASSPHRASE" ]; then
        echo "  -> passphrase bos, key korumasiz olusturulacak"
    else
        echo "ERROR: passphrase too short (min. 16 characters, or empty for no protection)" >&2
        exit 1
    fi
fi
# Hand the passphrase to gpg via --passphrase-file so it never appears in a
# process listing; stash it in a 0600 file under the (0700) keyring dir.
# gpg's batch --gen-key cannot read a passphrase file, so that fallback builds
# its control file with the passphrase inline and scrubs it afterwards.
mkdir -p "$GPG_KEYRING" && chmod 700 "$GPG_KEYRING"
umask 077
PASSPHRASE_FILE="$GPG_KEYRING/.passphrase.tmp"
BATCH_FILE="$GPG_KEYRING/.gen-key.batch"
printf '%s' "$PASSPHRASE" > "$PASSPHRASE_FILE"
unset PASSPHRASE
trap 'rm -f "$PASSPHRASE_FILE" "$BATCH_FILE"' EXIT

echo "==> Generating Nexus signing key ($KEY_NAME <$KEY_EMAIL>)"

# Drop any pre-existing Nexus master key (same UID) so the generated keyring,
# nexus.gpg and the reported fingerprint stay unambiguous. gpg allows multiple
# keys with the same UID; without this, `--export $KEY_EMAIL` and the
# fingerprint lookup would pick up stale keys.
# NOTE: --delete-secret-keys in batch mode rejects a UID/email ("bu, toplu iş
# kipinde yapılamaz") and requires the keygrip/fingerprint, so delete by
# fingerprint. Deleting does not need the key's passphrase.
_existing_fps="$(gpg --homedir "$GPG_KEYRING" --batch --with-colons --list-secret-keys "$KEY_EMAIL" 2>/dev/null \
    | awk -F: '/^fpr/ {print $10}')"
if [ -n "$_existing_fps" ]; then
    echo "  removing existing key(s): $(echo "$_existing_fps" | tr '\n' ' ')"
    for _fp in $_existing_fps; do
        gpg --homedir "$GPG_KEYRING" --batch --yes --delete-secret-keys "$_fp" \
            || { echo "ERROR: $_fp gizli anahtari silinemedi" >&2; exit 1; }
        gpg --homedir "$GPG_KEYRING" --batch --yes --delete-keys "$_fp" 2>/dev/null || true
    done
    unset _fp
    rm -f nexus.gpg nexus-trusted nexus-revoked
fi
unset _existing_fps

if gpg --homedir "$GPG_KEYRING" --batch --pinentry-mode loopback \
    --passphrase-file "$PASSPHRASE_FILE" --quick-generate-key \
    "$KEY_NAME <$KEY_EMAIL>" rsa4096 sign "$KEY_EXPIRE" 2>/dev/null; then
    :
else
    # Fallback for older gpg without --quick-generate-key. Read the passphrase
    # back from the file and inline it into the batch control file.
    _p="$(cat "$PASSPHRASE_FILE")"
    printf 'Key-Type: RSA\nKey-Length: 4096\nKey-Usage: sign\nName-Real: %s\nName-Email: %s\nExpire-Date: %s\nPassphrase: %s\n%%commit\n' \
        "$KEY_NAME" "$KEY_EMAIL" "$KEY_EXPIRE" "$_p" > "$BATCH_FILE"
    unset _p
    gpg --homedir "$GPG_KEYRING" --batch --pinentry-mode loopback \
        --gen-key "$BATCH_FILE" 2>/dev/null
fi

FP="$(gpg --homedir "$GPG_KEYRING" --with-colons --list-secret-keys "$KEY_EMAIL" | awk -F: '/^fpr/ {fp=$10} END {print fp}')"
if [ -z "$FP" ]; then
    echo "ERROR: failed to read the generated key fingerprint" >&2
    exit 1
fi
echo "==> Master key fingerprint: $FP"

gpg --homedir "$GPG_KEYRING" --armor --export "$KEY_EMAIL" > nexus.gpg
gpg --homedir "$GPG_KEYRING" --armor --export-ownertrust > nexus-trusted
: > nexus-revoked

echo "==> Wrote nexus.gpg, nexus-trusted, nexus-revoked"
echo "==> Note: add '$FP' to the nexus-trusted file if missing, and to the ISO's"
echo "    pacman-key trust via:  pacman-key --add nexus.gpg; pacman-key --lsign-key $FP"
echo ""
echo "==> BACKUP (do not skip):"
echo "    The secret key lives in $GPG_KEYRING/private-keys-v1.d/ and is the"
echo "    master key for every Nexus package. Back it up to an OFFLINE"
echo "    (air-gapped) location, NOT on the build machine. To export the key"
echo "    and a revocation certificate:"
echo ""
echo "        gpg --homedir '$GPG_KEYRING' --armor --export-secret-keys '$KEY_EMAIL' > nexus-master-key.asc"
echo "        gpg --homedir '$GPG_KEYRING' --gen-revoke '$KEY_EMAIL' > nexus-master-key-revoke.asc"
echo ""
echo "    Store both files (plus the passphrase, separately!) on an offline"
echo "    medium. Losing the key means re-signing the entire repository."
echo "    NEVER commit the secret key or the passphrase to git."
