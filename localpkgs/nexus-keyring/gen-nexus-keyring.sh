#!/usr/bin/env bash
# Generates the Nexus package signing keyring files used by the nexus-keyring
# package. Run this ONCE on the build host, then `makepkg -f` the keyring.
#
# The generated secret key is kept on the build host and is the master key for
# signing all Nexus repository packages. Back it up securely; losing it means
# re-signing the whole repository.
set -e

cd "$(dirname "$0")"

KEY_EMAIL="${NEXUS_KEY_EMAIL:-nexus@nexuslinux.org}"
KEY_NAME="${NEXUS_KEY_NAME:-Nexus Linux Packaging}"
KEY_EXPIRE="${NEXUS_KEY_EXPIRE:-2y}"
GPG_KEYRING="$PWD/gnupg"

echo "==> Generating Nexus signing key ($KEY_NAME <$KEY_EMAIL>)"
mkdir -p "$GPG_KEYRING" && chmod 700 "$GPG_KEYRING"

gpg --homedir "$GPG_KEYRING" --batch --pinentry-mode loopback --passphrase '' --quick-generate-key \
    "$KEY_NAME <$KEY_EMAIL>" rsa4096 sign "$KEY_EXPIRE" 2>/dev/null || {
    # fallback for older gpg without --quick-generate-key
    gpg --homedir "$GPG_KEYRING" --batch --pinentry-mode loopback --passphrase '' --gen-key <<EOF
Key-Type: RSA
Key-Length: 4096
Key-Usage: sign
Name-Real: $KEY_NAME
Name-Email: $KEY_EMAIL
Expire-Date: $KEY_EXPIRE
%no-protection
%commit
EOF
}

FP="$(gpg --homedir "$GPG_KEYRING" --with-colons --list-secret-keys "$KEY_EMAIL" | awk -F: '/^fpr/ {print $10; exit}')"
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
