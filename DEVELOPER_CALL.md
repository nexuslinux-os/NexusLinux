# Nexus Linux — Geliştirici Çağrısı / Developer Call

> **Bu proje şu an basit bir geliştirme ortamında yapılıyor.**  
> Derleme sorunları çözülüp GitHub Actions / CI/CD kurulunca geliştirme oraya taşınacak.

---

## 🎯 Vizyon

**Nexus Linux** — *Web-app tabanlı, hafif, güvenlik odaklı, Pure Arch tabanlı bir dağıtım.*

| Özellik | Plan |
|---------|------|
| **Taban** | Pure Arch (core/extra/multilib sadece) |
| **Masaüstü** | KDE Plasma (varsayılan), GNOME, COSMIC seçenekli |
| **Kurulum** | Calamares (kaynak koddan derlenir) |
| **Paket Yönetimi** | `pacman` + Flatpak (web-app'ler için) |
| **Güvenlik** | ClamAV, hardened kernel seçenekleri, AppArmor/SELinux profilleri |
| **Web-App Odaklı** | Flatpak/WebApp Manager entegrasyonu, PWA desteği |
| **Hafif** | Minimal ISO ~1.5GB, sadece gerekli servisler |

---

## 📍 Şu Anki Durum (2026-09)

| Bileşen | Durum |
|---------|-------|
| Pure Arch base | ✅ Tamamlandı |
| CachyOS kalıntıları | ✅ Tamamen temizlendi |
| Calamares (kaynak koddan) | 🔄 Derleme aşamasında |
| localpkgs (branding/keyring/wallpaper/calamares-config) | ✅ Eklendi |
| GRUB teması | ✅ Eklendi |
| Donanım sürücüleri (firmware/GPU/WiFi/Bluetooth/Printer) | ✅ Paket listelerine eklendi |
| ClamAV + ClamTK | ✅ Eklendi |
| Derleme scripti | 🔄 `libjsoncpp.so.26` hatası — çözülüyor |
| CI/CD (GitHub Actions) | ❌ Henüz yok |

> **Not:** Şu an `build-nexus-iso.sh` scripti manuel çalıştırılıyor. Derleme hatası (`cmake: libjsoncpp.so.26`) çözülmek üzere.

---

## 🛠 Geliştiriciysen Nasıl Yardımcı Olabilirsin?

| Alan | Ne Gerekiyor |
|------|--------------|
| **CI/CD** | GitHub Actions workflow: `makepkg`, `mkarchiso`, artifact upload |
| **Calamares** | Modül optimizasyonu, web-app kurulum seçeneği ekleme |
| **Güvenlik** | AppArmor profilleri, hardened kernel paketi, sbom imzalama |
| **Web-App** | Flatpak repo entegrasyonu, PWA installer, WebApp Manager |
| **Branding** | Duvar kağıtları, SDDM/Plymouth temaları, ikon seti |
| **Test** | Sanal makine / bare metal testleri, donanım uyumluluk raporları |
| **Dokümantasyon** | Wiki, kurulum rehberi, geliştirici kılavuzu |

---

## 🚀 Hızlı Başlangıç (Geliştiriciler İçin)

```bash
# Repo
git clone https://github.com/nexuslinux-os/NexusLinux
cd NexusLinux

# Bağımlılıklar (Arch/Arch-based)
sudo pacman -S archiso base-devel git cmake qt6-base qt6-declarative \
    kconfig kcoreaddons ki18n kparts yaml-cpp jsoncpp

# Local paketleri derle
for p in localpkgs/*/; do
    (cd "$p" && makepkg -sf --noconfirm --skippgpcheck)
done

# Calamares derle (tek seferlik)
git clone --depth 1 --branch v3.3.12 https://github.com/calamares/calamares
cd calamares && mkdir build && cd build
cmake .. -DCMAKE_INSTALL_PREFIX=/usr -DINSTALL_CONFIG=ON
make -j$(nproc) && sudo make install

# ISO build
./build-nexus-iso.sh desktop
```

---

## 📁 Yapı

```
NexusLinux/
├── archiso/                 # archiso profili (airootfs, packages, grub, syslinux)
│   ├── airootfs/            # Live sistem overlay
│   │   ├── etc/             # os-release, pacman.conf, calamares modules
│   │   ├── usr/share/nexus-calamares/  # Branding, modules, scripts
│   │   └── boot/grub/themes/nexus/     # GRUB teması
│   ├── packages*.x86_64     # Paket listeleri (x86_64, desktop, minimal)
│   └── buildiso.sh          # Upstream archiso build driver
├── localpkgs/               # Nexus özel paketler (makepkg)
│   ├── nexus-branding/      # os-release, lsb-release
│   ├── nexus-wallpapers/    # Duvar kağıtları
│   ├── nexus-keyring/       # İmzalama anahtarları
│   └── nexus-calamares/     # Calamares modülleri, branding, config
├── build-nexus-iso.sh       # Ana build scripti
├── build-nexus-repo.sh      # (Eski — local repo için, kullanılmıyor)
├── CHANGELOG.md             # Değişiklik günlüğü
├── README.md                # Proje tanımı
├── CONTRIBUTING.md          # Katkı rehberi
└── SECURITY.md              # Güvenlik politikası
```

---

## 💬 İletişim

- **Issues:** [GitHub Issues](https://github.com/nexuslinux-os/NexusLinux/issues)
- **Discussions:** [GitHub Discussions](https://github.com/nexuslinux-os/NexusLinux/discussions)
- **Email:** `nexuslinux@proton.me`
- **Social Networks:** Henüz yok

---

## ⚖️ Lisans

- **Kod:** GPL-3.0-or-later
- **Branding/Varlıklar:** CC-BY-SA-4.0
- **Pure Arch tabanlı** — Arch Linux paketleri kendi lisanslarıyla gelir.

---

> **"Basit başla, güvenli büyüt, web'e odaklan."**  
> Nexus Linux — Pure Arch. Web-first. Security-by-default.

> **Katkı sağlamak istersen:** Fork → Branch → PR. Her katkı değerlidir.
