# Maintainer: Nexus Linux
# Nexus KDE Plasma desktop defaults: stock panel layout, default Breeze look
# and Nexus wallpaper, shipped as /etc/skel so both the live user and installed
# systems start with the Nexus look. Replaces the CachyOS KDE settings.

pkgname=nexus-kde-settings
pkgver=2.0
pkgrel=1
pkgdesc='Default KDE Plasma settings for Nexus Linux (stock Breeze)'
arch=('any')
url='https://nexuslinux.org'
license=(GPL-3.0-or-later)
conflicts=('cachyos-kde-settings')
depends=('nexus-wallpapers')
source=(
    'kdeglobals'
    'kwinrc'
    'plasmarc'
    'plasma-org.kde.plasma.desktop-appletsrc'
)
sha512sums=('SKIP' 'SKIP' 'SKIP' 'SKIP')

package() {
    for f in kdeglobals kwinrc plasmarc plasma-org.kde.plasma.desktop-appletsrc; do
        install -Dm644 "$f" "$pkgdir/etc/skel/.config/$f"
        install -Dm644 "$f" "$pkgdir/usr/share/nexus-skel/.config/$f"
    done
}
