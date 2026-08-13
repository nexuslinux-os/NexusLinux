# Maintainer: Nexus Linux
# Ships the Nexus default wallpaper together with per-desktop-environment
# default wallpaper configuration, so freshly installed systems pick up the
# Nexus look regardless of the selected desktop environment.

pkgname=nexus-wallpapers
pkgver=1.0
pkgrel=1
pkgdesc='Default wallpapers and per-desktop wallpaper defaults for Nexus Linux'
arch=('any')
url='https://nexuslinux.org'
license=(GPL-3.0-or-later)
install='nexus-wallpapers.install'
conflicts=('cachyos-wallpapers')
source=(
    'wallpaper.png'
    'metadata.json'
    '00_nexus_wallpaper'
    'dconf-profile-user'
    'xfce4-desktop.xml'
    'lxqt-settings.conf'
    'lxde-pcmanfm.conf'
    'set-nexus-wallpaper'
    'nexus-wallpaper.desktop'
)
sha512sums=('SKIP' 'SKIP' 'SKIP' 'SKIP' 'SKIP' 'SKIP' 'SKIP' 'SKIP' 'SKIP')

package() {
    install -Dm644 wallpaper.png "$pkgdir/usr/share/backgrounds/nexus/wallpaper.png"
    install -Dm644 metadata.json "$pkgdir/usr/share/wallpapers/nexus/metadata.json"
    install -d "$pkgdir/usr/share/wallpapers/nexus/contents/images"
    ln -sf /usr/share/backgrounds/nexus/wallpaper.png \
        "$pkgdir/usr/share/wallpapers/nexus/contents/images/3840x2160.png"

    install -Dm644 00_nexus_wallpaper "$pkgdir/etc/dconf/db/local.d/00_nexus_wallpaper"
    install -Dm644 dconf-profile-user "$pkgdir/etc/dconf/profile/user"
    install -Dm644 xfce4-desktop.xml \
        "$pkgdir/etc/xdg/xfce4/xfconf/xfce-perchannel-xml/xfce4-desktop.xml"
    install -Dm644 lxqt-settings.conf "$pkgdir/etc/xdg/pcmanfm-qt/lxqt/settings.conf"
    install -Dm644 lxde-pcmanfm.conf "$pkgdir/etc/xdg/pcmanfm/LXDE/pcmanfm.conf"

    install -Dm755 set-nexus-wallpaper \
        "$pkgdir/usr/share/nexus-settings/scripts/set-nexus-wallpaper"
    install -Dm644 nexus-wallpaper.desktop \
        "$pkgdir/etc/xdg/autostart/nexus-wallpaper.desktop"
}
