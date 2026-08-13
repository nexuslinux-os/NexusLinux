# Maintainer: Nexus Linux
# Fork of cachyos-handheld (GPL-3.0-or-later). Handheld (Steam Deck like)
# support for Nexus Linux; content tracks the upstream CachyOS-Handheld repo
# (signed tag).

pkgname=nexus-handheld
pkgver=1.3.2
pkgrel=2
arch=('any')
license=('GPL-3.0-or-later')
pkgdesc='Nexus - Handheld!'
url='https://github.com/nexuslinux/nexuslinux'
source=("git+https://github.com/CachyOS/CachyOS-Handheld.git?signed#tag=$pkgver")
install="$pkgname.install"
options=(!strip !debug)
provides=('cachyos-deckify')
replaces=('cachyos-deckify')
conflicts=('cachyos-handheld')
sha256sums=('2a8b0b0c642c46bd7446749d9bf6da434695173d44da15d3c211a4a38508d5bd')
validpgpkeys=(
  E8B9AA39F054E30E8290D492C3C4820857F654FE  # Peter Jung <admin@ptr1337.dev>
  B1B70BB1CD56047DEF31DE2EB62C3D10C54D5DA9  # Vladislav Nepogodin <nepogodin.vlad@gmail.com>
  E18447AC260021D31F3FF6C4C8A2A4774B8B63C4  # Eric Naim <dnaim@cachyos.org>
)
makedepends=('git')
depends=(
  'cachyos-alacritty-config'
  'cachyos-vapor'
  'gamescope-session-cachyos'
  'jupiter-hw-support'
  'lib32-gamescope'
  'mangohud'
  'mesa-utils'
  'plasma-login-manager'
  'scx-scheds'
  'steamos-jupiter-stable'
)

package() {
  install -d "$pkgdir/etc"
  cp -rf "${srcdir}/CachyOS-Handheld/etc" "$pkgdir"
  install -d "$pkgdir/usr"
  cp -rf "${srcdir}/CachyOS-Handheld/usr" "$pkgdir"

  install -d "$pkgdir/usr/lib/firmware/ath11k"
  ln -s ./QCA2066 "$pkgdir/usr/lib/firmware/ath11k/QCA206X"
}
