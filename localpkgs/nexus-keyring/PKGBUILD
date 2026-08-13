# Maintainer: Nexus Linux
# Based on the official CachyOS cachyos-keyring PKGBUILD (GPL-3.0-or-later).
# Run gen-nexus-keyring.sh first to produce nexus.gpg / nexus-trusted /
# nexus-revoked, then build with:  makepkg -f

pkgname=nexus-keyring
pkgver=1
pkgrel=1
pkgdesc="Nexus keyring"
arch=('any')
url="https://nexuslinux.org"
license=('GPL-3.0-or-later')
conflicts=('cachyos-keyring')
provides=('cachyos-keyring')
install=$pkgname.install
source=("nexus.gpg"
        "nexus-revoked"
        "nexus-trusted"
        "$install")

sha512sums=('SKIP' 'SKIP' 'SKIP' 'SKIP')

package() {
    install -D -m0644 -t "${pkgdir}"/usr/share/pacman/keyrings/ 'nexus'{.gpg,-trusted,-revoked}
}
