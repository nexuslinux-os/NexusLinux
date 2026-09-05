# Nexus Linux - GitHub Issues Catalog

> **Source:** Code review of `nexuslinux-os/NexusLinux`  
> **Status:** All issues are **unresolved** - documented for tracking  
> **Labels:** Use appropriate labels when creating (`bug`, `security`, `enhancement`, `documentation`, `build`, `refactor`)

---

## 🔴 Critical Security & Production Issues

### #1 Placeholder GPG key in production
**Labels:** `security`, `bug`, `critical`  
**File:** `localpkgs/nexus-keyring/PKGBUILD`  
**Detail:** `nexus.gpg` contains `# Placeholder - replace with actual Nexus master key` instead of a real key. If this package is installed, signature verification will fail completely.  
**Fix:** Generate real GPG key pair, export public key to `nexus.gpg`, private key to secure offline storage.

---

### #2 Empty trusted/revoked keyring files
**Labels:** `security`, `bug`, `critical`  
**File:** `localpkgs/nexus-keyring/PKGBUILD`  
**Detail:** `nexus-trusted` and `nexus-revoked` contain only comment lines, no actual fingerprints.  
**Fix:** Populate with actual key fingerprints after generating master key.

---

### #3 Hardcoded developer directory in pacman.conf
**Labels:** `bug`, `build`, `critical`  
**File:** `archiso/pacman.conf`  
**Detail:** `Server = file:///home/cahit/Projeler/nexus-live/localrepo` — build will fail on any other machine.  
**Fix:** Use relative path or environment variable; inject at build time via script.

---

### #4 GPGKEY fingerprint mismatch
**Labels:** `security`, `bug`  
**Files:** `build-nexus-repo.sh` vs `README.md`  
**Detail:** Script uses `7E08C6020E20F32C9F95833C803D28F88FFED82B`, README shows `F4C57604C90E90CD6AB3633F2AA4846E14CBE512`. Which is correct?  
**Fix:** Align both to single authoritative fingerprint; document in one place.

---

### #5 Checksums skipped for nexus-kde-settings
**Labels:** `security`, `build`  
**File:** `localpkgs/nexus-kde-settings/PKGBUILD`  
**Detail:** `sha512sums=('SKIP' 'SKIP' 'SKIP' 'SKIP')` — no integrity verification of sources.  
**Fix:** Compute and add actual sha512sums for all source files.

---

### #6 Upstream PGP key mismatch in nexus-settings
**Labels:** `security`, `build`  
**File:** `build-nexus-repo.sh`  
**Detail:** `_UPSTREAM_KEYS` includes `E18447AC260021D31F3FF6C4C8A2A4774B8B63C4` labeled as `(nexus-packageinstaller / handheld)` but actually used by `nexus-settings`. Naming inconsistency.  
**Fix:** Correct label to match actual usage; verify key ownership.

---

### #7 SigLevel = Never in build pacman.conf
**Labels:** `security`, `build`  
**File:** `build-nexus-repo.sh`  
**Detail:** `[nexus]` repo uses `SigLevel = Never` during build. Acceptable for isolated build but dangerous if accidentally deployed to live system.  
**Fix:** Ensure build pacman.conf never leaks to installed system; add explicit comment/warning.

---

### #8 GPG passphrase hex dump in logs
**Labels:** `security`, `bug`  
**File:** `build-nexus-repo.sh`  
**Detail:** `od -An -tx1 | tr -d ' \n'` outputs passphrase as hex to stdout — visible in build logs.  
**Fix:** Avoid logging passphrase; use secure gpg-agent preset without echoing.

---

## 🟠 Structural / Architectural Issues

### #9 Duplicate package lists
**Labels:** `refactor`, `build`  
**Files:** `archiso/packages.x86_64`, `archiso/packages_desktop.x86_64`  
**Detail:** Both files identical. `prepare_profile` copies `packages_desktop.x86_64` → `packages.x86_64`. Redundant.  
**Fix:** Remove `packages.x86_64`; use single source of truth.

---

### #10 Minimal profile includes heavy packages
**Labels:** `refactor`, `enhancement`  
**File:** `archiso/packages_minimal.x86_64`  
**Detail:** "Minimal" profile includes `nvidia-dkms`, `nvidia-utils`, `plymouth`, `plasma-login-manager`, `spectacle`. Not minimal.  
**Fix:** Create true minimal profile; move heavy packages to desktop-only.

---

### #11 Monolithic nexus-calamares PKGBUILD
**Labels:** `refactor`, `maintenance`  
**File:** `localpkgs/nexus-calamares/PKGBUILD`  
**Detail:** 500+ line single PKGBUILD containing Calamares modules, branding, skel configs, color schemes, splash screen, shellprocess config. Unmaintainable.  
**Fix:** Split into separate packages: `nexus-calamares-modules`, `nexus-calamares-branding`, `nexus-calamares-skel`, `nexus-calamares-theme`.

---

### #12 DRY violation in nexus-branding
**Labels:** `refactor`, `cleanup`  
**File:** `localpkgs/nexus-branding/PKGBUILD`  
**Detail:** Writes `/etc/os-release`, `/usr/lib/os-release`, `/etc/lsb-release` with identical content.  
**Fix:** Generate once, symlink or install to multiple locations.

---

### #13 Calamares config duplication
**Labels:** `refactor`, `cleanup`  
**File:** `localpkgs/nexus-calamares/PKGBUILD`  
**Detail:** `settings_offline.conf` and `settings.conf` share nearly identical `sequence` blocks.  
**Fix:** Use single template with conditional includes; generate both at package build time.

---

### #14 GitHub Releases as package mirror
**Labels:** `architecture`, `enhancement`  
**Files:** `README.md`, `release-nexus.sh`  
**Detail:** GitHub Releases used as package mirror via `latest/download/`. Race condition on concurrent releases; not designed for package hosting.  
**Fix:** Use proper package hosting (GitHub Packages, custom server, or mirror network).

---

### #15 Incorrect license for nexus-settings
**Labels:** `legal`, `bug`  
**File:** `localpkgs/nexus-settings/PKGBUILD`  
**Detail:** Uses `GPL-1.0-only` but upstream CachyOS-Settings likely GPL-2.0+ or different.  
**Fix:** Verify upstream license; correct to match.

---

### #16 All checksums SKIP in nexus-hooks
**Labels:** `security`, `build`  
**File:** `localpkgs/nexus-hooks/PKGBUILD`  
**Detail:** 8 source files all with `sha512sums=('SKIP')` — no integrity verification.  
**Fix:** Add actual checksums.

---

### #17 Conflicting calamares packages
**Labels:** `build`, `conflict`  
**Files:** `localpkgs/nexus-calamares/PKGBUILD` + `build-nexus-iso.sh`  
**Detail:** `nexus-calamares` depends on `calamares` but build script also builds separate `calamares` package. Two different calamares packages may conflict.  
**Fix:** Remove `depends=(calamares)` from nexus-calamares; ensure only one calamares package exists (the custom-built one).

---

## 🟡 Code Quality & Script Issues

### #18 Inconsistent shebang
**Labels:** `style`, `cleanup`  
**Files:** Multiple  
**Detail:** `build-nexus-iso.sh` uses `#!/usr/bin/env bash`, `util-iso.sh` uses `#!/bin/bash`.  
**Fix:** Standardize on `#!/usr/bin/env bash` for portability.

---

### #19 Inconsistent strict mode
**Labels:** `style`, `robustness`  
**Files:** Multiple  
**Detail:** `build-nexus-iso.sh` has `set -e` + `set -o pipefail` but no `set -u`. `release-nexus.sh` uses `set -euo pipefail`. No project-wide standard.  
**Fix:** Adopt `set -euo pipefail` project-wide; add to all scripts.

---

### #20 Hardcoded path in comment
**Labels:** `cleanup`, `docs`  
**File:** `build-nexus-iso.sh`  
**Detail:** Comment contains `cd /home/cahit/Projeler/nexus-live/NexusLinux` — hardcoded developer path.  
**Fix:** Remove or parameterize.

---

### #21 Aggressive `--overwrite '*'`
**Labels:** `safety`, `bug`  
**File:** `build-nexus-iso.sh`  
**Detail:** `sudo pacman -S --overwrite '*' cmake` — overwrites ALL conflicting files silently.  
**Fix:** Use specific file conflicts or proper pacman conflict resolution.

---

### #22 Host mkarchiso patching
**Labels:** `safety`, `maintenance`  
**File:** `util-iso.sh`  
**Detail:** Patches `/usr/bin/mkarchiso` directly with `sed`. Arch update may break patch; modifies system tool.  
**Fix:** Use `--overwrite` flag via pacman config instead of patching host binary.

---

### #23 Global variable scope in util-iso.sh
**Labels:** `refactor`, `bug-risk`  
**File:** `util-iso.sh`  
**Detail:** Functions use `${src_dir}` but it's defined globally in `buildiso.sh`. Refactoring breaks easily.  
**Fix:** Pass `src_dir` as parameter to functions.

---

### #24 Undefined function calls in trap_exit
**Labels:** `bug`, `robustness`  
**File:** `buildiso.sh`  
**Detail:** `trap_exit` calls `error`, `umount_fs`, `umount_img` but they're not defined in this file; depend on imports from `util-msg.sh` and `util-iso-mount.sh`. Wrong import order = silent failure.  
**Fix:** Source dependencies explicitly at top; validate functions exist.

---

### #25 RAM check uses /proc/meminfo
**Labels:** `portability`, `bug`  
**File:** `buildiso.sh`  
**Detail:** `grep MemTotal /proc/meminfo` — Linux-specific; won't work on macOS/BSD build hosts.  
**Fix:** Use `free` or detect OS; fallback gracefully.

---

### #26 Silent failure when ISO not found
**Labels:** `robustness`, `bug`  
**File:** `build-nexus-iso.sh`  
**Detail:** `find ... -name '*.iso'` returns empty → only prints error but continues with exit 0.  
**Fix:** Add `exit 1` after error message.

---

### #27 `repo-add --new` clears repo on failure
**Labels:** `robustness`, `build`  
**File:** `build-nexus-iso.sh`  
**Detail:** `repo-add --new` wipes existing repo DB. If Calamares build fails after, repo is empty.  
**Fix:** Build packages first, then create repo DB atomically at end.

---

### #28 Race condition in find + cp
**Labels:** `robustness`, `bug`  
**File:** `build-nexus-repo.sh`  
**Detail:** `find ... -print0 | xargs -0 cp` — if new packages added during copy, may miss or duplicate.  
**Fix:** Build complete package list first, then copy.

---

### #29 GitHub release tag collision
**Labels:** `robustness`, `ci`  
**File:** `release-nexus.sh`  
**Detail:** `new_tag()` uses `date -u +%Y.%m.%d`. Two builds same day → `-1`, `-2` suffix but race condition if parallel.  
**Fix:** Include timestamp/UUID: `%Y.%m.%d-%H%M%S` or use git commit hash.

---

### #30 Inconsistent gpg signing retry
**Labels:** `robustness`, `release`  
**File:** `release-nexus.sh`  
**Detail:** First sign attempt uses one flag set, retry uses different flags. Inconsistent error handling.  
**Fix:** Standardize signing command; retry with same flags.

---

### #31 nexus-calamares heredoc stdin pattern
**Labels:** `robustness`, `maintenance`  
**File:** `localpkgs/nexus-calamares/PKGBUILD`  
**Detail:** `install -m644 /dev/stdin "$pkgdir/..." <<'EOF'` used 20+ times. If heredoc malformed or empty → zero-byte file silently created.  
**Fix:** Use external source files; avoid massive heredocs in PKGBUILD.

---

### #32 Mixed placeholder syntax in shellprocess.conf
**Labels:** `bug`, `calamares`  
**File:** `localpkgs/nexus-calamares/PKGBUILD`  
**Detail:** `${ROOT}`, `@@ROOT@@`, `@@USER@@` mixed. Calamares substitution behavior unclear; `${ROOT}` likely not expanded.  
**Fix:** Standardize on Calamares-native `@@VAR@@` syntax only.

---

### #33 Duplicate avahi in package list
**Labels:** `cleanup`, `build`  
**File:** `archiso/packages.x86_64`  
**Detail:** `avahi` listed twice.  
**Fix:** Remove duplicate.

---

### #34 Missing nexus-wallpapers package
**Labels:** `dependency`, `bug`  
**File:** `localpkgs/nexus-kde-settings/PKGBUILD`  
**Detail:** `depends=('nexus-wallpapers')` but `nexus-wallpapers` PKGBUILD not found in repo.  
**Fix:** Create `localpkgs/nexus-wallpapers/PKGBUILD` or remove dependency.

---

### #35 Hardcoded upstream tag in nexus-settings
**Labels:** `maintenance`, `upstream`  
**File:** `localpkgs/nexus-settings/PKGBUILD`  
**Detail:** `source=("git+$url.git?signed#tag=$pkgver")` with `pkgver=1.3.5` hardcoded. Upstream updates ignored.  
**Fix:** Use `pkgver()` function to fetch latest tag dynamically.

---

### #36 NoExtract in pacman.conf instead of overlay
**Labels:** `architecture`, `cleanup`  
**File:** `archiso/pacman.conf`  
**Detail:** `NoExtract = etc/calamares/modules/netinstall.yaml` — excludes files from pacman install but better handled in airootfs overlay.  
**Fix:** Move to airootfs overlay; remove from pacman.conf.

---

## 🔵 Documentation & Process Gaps

### #37 Missing CONTRIBUTING.md
**Labels:** `documentation`, `process`  
**Detail:** No contribution guide, code style, commit message format, PR workflow.

---

### #38 Missing CHANGELOG.md
**Labels:** `documentation`, `release`  
**Detail:** No version history, breaking changes, migration notes documented.

---

### #38 No CI/CD pipeline
**Labels:** `ci`, `automation`  
**Detail:** No `.github/workflows/`. All builds manual; signing, release, artifact upload all manual.

---

### #39 Missing LICENSE file
**Labels:** `legal`, `documentation`  
**Detail:** Repo root lacks `LICENSE` file. Packages declare `GPL-3.0-or-later` but repo-level license missing.

---

### #39 No Issue/PR templates
**Labels:** `process`, `documentation`  
**Detail:** No `.github/ISSUE_TEMPLATE/` or `.github/PULL_REQUEST_TEMPLATE/`.

---

### #40 Missing CODE_OF_CONDUCT.md
**Labels:** `community`, `documentation`  
**Detail:** No community guidelines, enforcement, reporting process.

---

### #40 Missing SECURITY.md
**Labels:** `security`, `process`  
**Detail:** No vulnerability disclosure policy, GPG key compromise procedure, security contact.

---

### #41 Hardcoded path in README
**Labels:** `documentation`, `bug`  
**File:** `README.md`  
**Detail:** `cd /home/cahit/Projeler/nexus-live/NexusLinux` — user must adapt but not documented.

---

### #41 Missing nexus-keyring.install
**Labels:** `bug`, `build`  
**File:** `localpkgs/nexus-keyring/PKGBUILD`  
**Detail:** `install=nexus-keyring.install` declared but file missing. Build will fail.

---

## 📋 Summary

| Severity | Count |
|----------|-------|
| 🔴 Critical Security/Production | 8 |
| 🟠 Structural/Architectural | 9 |
| 🟡 Code Quality/Script | 18 |
| 🔵 Documentation/Process | 7 |
| **Total** | **42** |

---

## 🎯 Suggested Priority Order

1. **P0 (Blockers):** #1, #2, #3, #4, #5, #7, #8, #26, #41
2. **P1 (High):** #6, #9, #10, #11, #17, #22, #24, #25, #27, #29
3. **P2 (Medium):** #12, #13, #14, #15, #16, #18-21, #23, #28, #30-36
4. **P3 (Low):** #37-#43 (documentation/process)

---

> **Note:** This catalog was generated via automated + manual code review. Verify each issue before acting. Some may be false positives or already addressed in recent commits.