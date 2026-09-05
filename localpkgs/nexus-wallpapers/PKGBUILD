# Maintainer: Nexus Linux <nexus@nexuslinux.org>
pkgname=nexus-wallpapers
pkgver=1.0
pkgrel=1
pkgdesc="Nexus Linux default wallpapers"
arch=(any)
url="https://github.com/nexuslinux-os/NexusLinux"
license=(GPL-3.0-or-later)
package() {
    # Create wallpaper directory
    install -dm755 "$pkgdir/usr/share/backgrounds/nexus"
    
    # Generate a simple default wallpaper using Python
    python3 -c "
from PIL import Image, ImageDraw, ImageFont
img = Image.new('RGB', (3840, 2160), '#1a1a2e')
draw = ImageDraw.Draw(img)
# Gradient background
for y in range(2160):
    r = int(0x1a + (0x0f - 0x1a) * y / 2160)
    g = int(0x1a + (0x0f - 0x1a) * y / 2160)
    b = int(0x2e + (0x1a - 0x2e) * y / 2160)
    draw.line([(0, y), (3840, y)], fill=(r, g, b))
# Circle
draw.ellipse([1840, 960, 2000, 1120], fill='#1793d1')
# Text
try:
    font_title = ImageFont.truetype('/usr/share/fonts/TTF/DejaVuSans-Bold.ttf', 72)
    font_sub = ImageFont.truetype('/usr/share/fonts/TTF/DejaVuSans.ttf', 36)
except:
    font_title = ImageFont.load_default()
    font_sub = ImageFont.load_default()
draw.text((1920, 1180), 'Nexus Linux', fill='white', font=font_title, anchor='mm')
draw.text((1920, 1260), 'Pure Arch Based', fill='#888888', font=font_sub, anchor='mm')
img.save('$pkgdir/usr/share/backgrounds/nexus/default.png')
" 2>/dev/null || {
        # Fallback: create solid color wallpaper if PIL not available
        python3 -c "
import struct, zlib
width, height = 3840, 2160
color = (0x1a, 0x1a, 0x2e, 0xff)
raw = b''.join(b'\x00' + bytes(color[:3]) * width for _ in range(height))
compressed = zlib.compress(raw)
png = b'\x89PNG\r\n\x1a\n'
ihdr = struct.pack('>IIBBBBB', width, height, 8, 6, 0, 0, 0)
png += struct.pack('>I', len(ihdr)) + b'IHDR' + ihdr + struct.pack('>I', zlib.crc32(b'IHDR' + ihdr) & 0xffffffff)
png += struct.pack('>I', len(compressed)) + b'IDAT' + compressed + struct.pack('>I', zlib.crc32(b'IDAT' + compressed) & 0xffffffff)
png += struct.pack('>I', 0) + b'IEND' + struct.pack('>I', zlib.crc32(b'IEND') & 0xffffffff)
with open('$pkgdir/usr/share/backgrounds/nexus/default.png', 'wb') as f:
    f.write(png)
"
    }
    
    # Symlink for Plasma
    install -dm755 "$pkgdir/usr/share/wallpapers/nexus"
    ln -sf ../backgrounds/nexus/default.png "$pkgdir/usr/share/wallpapers/nexus/default.png"
}