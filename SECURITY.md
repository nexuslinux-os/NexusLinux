# Security Policy

## Supported versions

Only the latest published release is actively maintained for security fixes.
All prior releases are EOL.

## Reporting a vulnerability

Please **do not** open a public GitHub issue for security vulnerabilities.

Instead, report privately so the issue can be fixed before disclosure:

- Email: `security@nexuslinux.org` (GPG-encrypted if possible; the public key is
  the Nexus master key listed in `README.md`)
- Or use GitHub's private disclosure: open a new issue and select the
  "Report a security vulnerability" / private advisory flow on
  `https://github.com/nexuslinux-os/NexusLinux/security/advisories/new`

Please include:

- A description of the vulnerability and its impact
- Steps to reproduce or a proof of concept
- Affected components/packages (e.g. an ISO build, a package, the installer)
- Suggested fix, if you have one

You should receive an acknowledgement within 3 business days. We will keep you
informed as the issue is investigated and published. Security fixes are
backported to the current release and announced in the release notes.

## Security considerations for maintainers

### Signing key

- The Nexus master signing key is protected by a passphrase (see
  `localpkgs/nexus-keyring/gen-nexus-keyring.sh`). The passphrase must never be
  committed to the repository or shared with third parties.
- The private key must be backed up to an **offline** (air-gapped) medium. Do
  not keep it only on the build machine. Losing it means re-signing the whole
  repository.
- `pacman.conf` uses `SigLevel = Required DatabaseOptional` for both `[cachyos]`
  and `[nexus]`: package signatures are always verified against the trusted
  keyring. `TrustAll` is deliberately **not** used. Do not weaken this.
- CI signing is done with the key restored from GitHub Actions secrets
  (`NEXUS_KEY_ASC`, `NEXUS_KEY_PASSPHRASE`); the key material never enters the
  repository.

### Supply chain

- Upstream sources (git tags) are fetched with `makepkg --verifysource` and
  their PGP signatures are verified against the upstream keys imported into the
  Nexus keyring (`build-nexus-repo.sh`).
- The repository database (`nexus.db`) and every package are signed with the
  Nexus master key before publishing (`repo-add -s`).
- ISO artifacts are signed, and a `SHA256SUMS` file is published alongside each
  release (`build-nexus-iso.sh` step [6/6]).
