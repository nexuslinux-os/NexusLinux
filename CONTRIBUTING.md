# Contributing to Nexus Linux

Thanks for your interest in Nexus Linux! This project is a fork of CachyOS that
rebuilds the CachyOS package set under Nexus branding.

## Code of conduct

Be respectful, constructive and inclusive. Harassment, trolling and personal
attacks are not tolerated.

## How to contribute

### Reporting bugs

- Open an issue at `https://github.com/nexuslinux/nexuslinux/issues`.
- Include the Nexus version, the ISO build date (`cat /etc/version-tag`), the
  hardware profile (if relevant) and the exact steps to reproduce.
- For security vulnerabilities use the private disclosure path — see
  `SECURITY.md`.

### Submitting changes

1. Fork the repository and create a feature branch.
2. Make focused changes; one logical change per commit.
3. Run the checks below before opening a pull request.
4. Open a pull request against `main` with a clear description.

## Building

A build requires Arch Linux with `pacman`, `makepkg`, `mkarchiso` and the
tooling listed in `build-nexus-iso.sh` step [2/6]. It runs on a real Arch host
(not a non-Arch sandbox):

```bash
./build-nexus-iso.sh desktop   # full ISO build (fork packages -> local repo -> ISO)
```

`build-nexus-repo.sh` builds the fork packages and local repository alone:

```bash
./build-nexus-repo.sh            # build packages + create local repo (no swap)
./build-nexus-repo.sh --apply-swap  # also wire nexus-* packages into the ISO profile
```

The fork packages live in `localpkgs/<name>/PKGBUILD`. Each one is a fork of the
CachyOS equivalent (see the `url=` field) with Nexus branding applied in
`prepare()`/`package()`.

## Checks

Run these before opening a pull request:

1. **Shell syntax**: `bash -n` on every modified shell script.
2. **ShellCheck**: `shellcheck --shell=bash --severity=warning` on shell scripts
   (also runs in CI).
3. **Package sources**: `makepkg --verifysource` in each modified
   `localpkgs/<name>/`.
4. **Build** the affected package(s) with `./build-nexus-repo.sh`.

CI runs ShellCheck and `makepkg --verifysource` on every push. A full ISO build
is available via the `build-iso` workflow (manual dispatch or tag).

## Signing key

All Nexus packages and the repository database are signed with the Nexus master
key (see `README.md` → "Signing key"). You do **not** need the key to build a
package — `makepkg -df` builds unsigned — but a signed build requires the key
and its passphrase (`NEXUS_KEY_PASSPHRASE`). The private key is never committed;
keep it offline and passphrase-protected.

## Branching / releases

- `main` is the integration branch. All pull requests target `main`.
- Releases are tagged (see `release-nexus.sh`); the tag triggers the ISO build
  workflow and the release pipeline.

## Getting help

- Project status and release notes: GitHub Releases.
- For questions, open a discussion or an issue in this repository.
