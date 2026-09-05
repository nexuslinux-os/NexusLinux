# Maintainer: Nexus Linux <nexus@nexuslinux.org>
pkgname=nexus-kde-settings
pkgver=1.0
pkgrel=1
pkgdesc="Default KDE Plasma settings for Nexus Linux"
arch=(any)
url="https://github.com/nexuslinux-os/NexusLinux"
license=(GPL-3.0-or-later)
depends=(nexus-wallpapers plasma-workspace)
install=nexus-kde-settings.install
source=(
    kdeglobals
    kwinrc
    plasmarc
    plasma-org.kde.plasma.desktop-appletsrc
    nexus-kde-settings.install
)
sha256sums=('5e6626cd390f61965810581125d6d673dde0c031b231daf4c256dd85f7bf13e6'
           '474d3235453cb5d6d028acb8214943e116e4f19ad52f72a86af5b9b7b774469a'
           'f7d42bb882633d4f01fe584318bbab5d0f29b09ff1059b0e19f802b74f65303d'
           'd6939b163c5906f41056597c05ec107d382cabb1ec2ee9a2bdada79ebbc96576'
           '9fd89f66bd62f4710bcf8d5feff2973a6131140d3018f7e629432347b66f8a6f')

package() {
    install -dm755 "$pkgdir/usr/share/nexus-kde-settings"
    
    install -m644 kdeglobals "$pkgdir/usr/share/nexus-kde-settings/kdeglobals"
    install -m644 kwinrc "$pkgdir/usr/share/nexus-kde-settings/kwinrc"
    install -m644 plasmarc "$pkgdir/usr/share/nexus-kde-settings/plasmarc"
    install -m644 plasma-org.kde.plasma.desktop-appletsrc "$pkgdir/usr/share/nexus-kde-settings/plasma-org.kde.plasma.desktop-appletsrc"
    
    # Install to nexus-skel for live user
    install -dm755 "$pkgdir/usr/share/nexus-skel/.config"
    install -m644 kdeglobals "$pkgdir/usr/share/nexus-skel/.config/kdeglobals"
    install -m644 kwinrc "$pkgdir/usr/share/nexus-skel/.config/kwinrc"
    install -m644 plasmarc "$pkgdir/usr/share/nexus-skel/.config/plasmarc"
    install -m644 plasma-org.kde.plasma.desktop-appletsrc "$pkgdir/usr/share/nexus-skel/.config/plasma-org.kde.plasma.desktop-appletsrc"
}