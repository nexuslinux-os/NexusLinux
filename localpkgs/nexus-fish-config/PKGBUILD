# Maintainer: Nexus Linux
# Fork of cachyos-fish-config (MIT). Fish shell configuration for Nexus Linux:
# fastfetch greeting, aliases and command completion notifications.

pkgname=nexus-fish-config
pkgver=1.0
pkgrel=1
pkgdesc="Fish configuration of Nexus Linux"
arch=('any')
url="https://github.com/nexuslinux/nexus-fish-config"
license=('MIT')
conflicts=('cachyos-fish-config')
provides=('cachyos-fish-config')
depends=(
  bat
  expac
  eza
  fastfetch
  fish
  fish-autopair
  fish-pure-prompt
  fisher
  fzf
  pkgfile
  tealdeer
  ttf-fantasque-nerd
)
source=(
    'conf.d/done.fish'
    'nexus-config.fish'
    'config.fish'
)
sha512sums=('SKIP' 'SKIP' 'SKIP')

package() {
    # makepkg flattens subdirectory sources to their basename in $srcdir, so
    # conf.d/done.fish lands as $srcdir/done.fish.
    install -Dm644 "$srcdir/done.fish" $pkgdir/usr/share/nexus-fish-config/conf.d/done.fish
    install -Dm644 nexus-config.fish $pkgdir/usr/share/nexus-fish-config/nexus-config.fish
    install -Dm644 config.fish $pkgdir/etc/skel/.config/fish/config.fish
}
