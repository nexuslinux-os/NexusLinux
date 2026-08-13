# Maintainer: Nexus Linux
# Fork of cachyos-hooks (GPL-3.0-or-later). Provides the Nexus libalpm hooks:
# os-release/lsb-release/issue branding, initramfs regeneration after plymouth
# updates and the reboot-required notification.

pkgname=nexus-hooks
pkgver=1.0
pkgrel=1
pkgdesc='Nexus libalpm hooks'
arch=('any')
license=(GPL-3.0-or-later)
depends=('systemd')
conflicts=('cachyos-hooks')
provides=('cachyos-hooks')
source=(
    'nexus-branding'
    'nexus-branding.hook'
    'nexus-os-release.hook'
    'nexus-lsb-release.hook'
    'nexus-plymouth-initramfs.hook'
    'nexus-reboot-required'
    'nexus-reboot-required.hook'
    'update-initramfs'
)
sha512sums=('SKIP' 'SKIP' 'SKIP' 'SKIP' 'SKIP' 'SKIP' 'SKIP' 'SKIP')

package() {
    install -Dm755 nexus-branding "$pkgdir/usr/share/libalpm/scripts/nexus-branding"
    install -Dm644 nexus-branding.hook "$pkgdir/usr/share/libalpm/hooks/nexus-branding.hook"
    install -Dm644 nexus-os-release.hook "$pkgdir/usr/share/libalpm/hooks/nexus-os-release.hook"
    install -Dm644 nexus-lsb-release.hook "$pkgdir/usr/share/libalpm/hooks/nexus-lsb-release.hook"
    install -Dm644 nexus-plymouth-initramfs.hook "$pkgdir/usr/share/libalpm/hooks/nexus-plymouth-initramfs.hook"
    install -Dm755 nexus-reboot-required "$pkgdir/usr/share/libalpm/scripts/nexus-reboot-required"
    install -Dm644 nexus-reboot-required.hook "$pkgdir/usr/share/libalpm/hooks/nexus-reboot-required.hook"
    install -Dm755 update-initramfs "$pkgdir/usr/bin/update-initramfs"
}
