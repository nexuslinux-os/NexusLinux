#!/usr/bin/env bash
set -e

# cachyos-calamares-next owns /etc/calamares/modules/netinstall.yaml and
# packagechooser_desktop.conf, so they cannot ship in the profile airootfs
# (pacstrap aborts on the file conflict). Install the Nexus copies from the
# non-conflicting staging path on top, after all packages are in place.
NEXUS_CALAMARES=/usr/share/nexus-calamares/modules
for conf in netinstall.yaml packagechooser_desktop.conf shellprocess.conf; do
    if [ -f "$NEXUS_CALAMARES/$conf" ]; then
        install -Dm644 "$NEXUS_CALAMARES/$conf" "/etc/calamares/modules/$conf"
    fi
done

# Bake Nexus branding into Calamares at build time so even a manual `calamares`
# launch (not going through the launch scripts) shows Nexus, not CachyOS:
# - branding directory
# - /etc/calamares/settings.conf from the online (normal install) flow
# - welcome/users module strings patched to Nexus
if [ -d /usr/share/nexus-calamares/branding/nexus ]; then
    cp -r /usr/share/nexus-calamares/branding/nexus /usr/share/calamares/branding/nexus
fi
if [ -f /usr/share/calamares/settings_online.conf ]; then
    install -Dm644 /usr/share/calamares/settings_online.conf /etc/calamares/settings.conf
fi
sed -i 's/CachyOS/Nexus Linux/g' /etc/calamares/modules/welcome.conf
sed -i 's/cachyos-${cpu}/nexus-${cpu}/' /etc/calamares/modules/users.conf

# The cachyos-kde-settings package ships its own configs into /etc/skel/.config and
# overwrites whatever was placed in the profile airootfs during pacstrap. The canonical
# Nexus desktop layout therefore lives in /usr/share/nexus-skel and is applied here, after
# all packages are installed. mkarchiso copies /etc/skel into the live user's home before
# this script runs, so we write to both /etc/skel (used for installed systems) and
# /home/liveuser (used by the live session).
NEXUS_SKEL=/usr/share/nexus-skel/.config
for conf in kdeglobals kwinrc plasmarc plasma-org.kde.plasma.desktop-appletsrc; do
    if [ -f "$NEXUS_SKEL/$conf" ]; then
        install -Dm644 "$NEXUS_SKEL/$conf" "/etc/skel/.config/$conf"
        if [ -d /home/liveuser ]; then
            install -Dm644 "$NEXUS_SKEL/$conf" "/home/liveuser/.config/$conf"
        fi
    fi
done

# Nexus ships a completely default KDE (stock Breeze) with only the wallpaper changed.
# cachyos-kde-settings pushes its own look into the skeleton via config files we do not
# overwrite above, so drop them from both the installed-system skeleton and the live
# user's home. This keeps the default Plasma theme, cursor, GTK look and panel layout.
for _skel in /etc/skel /home/liveuser; do
    [ -d "$_skel" ] || continue
    rm -rf "$_skel/.config/kdedefaults"
    rm -f "$_skel/.config/plasmashellrc"
    rm -f "$_skel/.config/Trolltech.conf"
    rm -f "$_skel/.config/kcminputrc"
    rm -rf "$_skel/.config/gtk-3.0"
    rm -rf "$_skel/.config/gtk-4.0"
    rm -rf "$_skel/.config/xsettingsd"
    rm -f "$_skel/.config/dconf/user"
done

# The Calamares keyboard module reads /usr/share/X11/xkb/rules/base.lst at
# runtime and offers every layout/variant listed there. Remove the Kurdish
# (Kurdish) variants so Kurdish no longer appears in the installer's keyboard
# options. The rules files are owned by the xkeyboard-config package, so they
# must be patched here (after pacstrap), not shipped in the profile airootfs.
for _rules in base.lst evdev.lst; do
    _rules="/usr/share/X11/xkb/rules/$_rules"
    if [ -f "$_rules" ]; then
        sed -i '/^  ku[ _]/d' "$_rules"
    fi
done

# Same for the XML rules files, which KDE's keyboard settings reads.
for _rules in base.xml evdev.xml; do
    _rules="/usr/share/X11/xkb/rules/$_rules"
    if [ -f "$_rules" ]; then
        python3 - "$_rules" <<'PYEOF'
import re, sys
path = sys.argv[1]
with open(path, encoding='utf-8') as f:
    data = f.read()
# Remove <variant> blocks whose <name> is a Kurdish variant (ku, ku_alt, ku_f, ku_ara)
data = re.sub(
    r'\s*<variant>\s*<configItem>\s*<name>ku(?:_\w+)?</name>.*?</variant>',
    '',
    data,
    flags=re.S,
)
with open(path, 'w', encoding='utf-8') as f:
    f.write(data)
PYEOF
    fi
done

# The cachyos-branding os-release hook writes "CachyOS" into /etc/os-release during
# pacstrap. Overwrite it so the live session identifies as Nexus Linux. Preserve the
# IMAGE_ID/IMAGE_VERSION lines appended by mkarchiso.
_IMAGE_ID="$(sed -n 's/^IMAGE_ID=//p' /etc/os-release)"
_IMAGE_VERSION="$(sed -n 's/^IMAGE_VERSION=//p' /etc/os-release)"
cat > /etc/os-release <<EOF
NAME="Nexus Linux"
PRETTY_NAME="Nexus Linux"
ID=nexus
ID_LIKE=arch
BUILD_ID=rolling
ANSI_COLOR="38;2;23;147;209"
IMAGE_ID=${_IMAGE_ID}
IMAGE_VERSION=${_IMAGE_VERSION}
EOF

# Nexus-branded lsb-release for the live session.
cat > /etc/lsb-release <<EOF
LSB_VERSION=1.4
DISTRIB_ID=Nexus
DISTRIB_RELEASE=rolling
DISTRIB_DESCRIPTION="Nexus Linux"
EOF

# Launch the Calamares installer directly on the live desktop instead of a
# welcome app. The launcher always runs the normal (offline) install flow.
mkdir -p /etc/skel/.config/autostart
cat > /etc/skel/.config/autostart/calamares.desktop <<'EOF'
[Desktop Entry]
Terminal=false
Type=Application
Categories=System;
StartupNotify=false
Name=Install Nexus Linux
Name[tr]=Nexus Linux Kur
Exec=/usr/local/bin/launch-calamares.sh
Icon=calamares
Comment=Install Nexus Linux on this computer.
Comment[tr]=Nexus Linux'u bu bilgisayara kur.
EOF

# mkarchiso copies /etc/skel into /home/liveuser before this script runs, so
# the autostart dir does not exist there yet. Create it unconditionally,
# otherwise Calamares would never autostart in the live session.
mkdir -p /home/liveuser/.config/autostart
cp /etc/skel/.config/autostart/calamares.desktop /home/liveuser/.config/autostart/calamares.desktop

# Compile the Nexus dconf database so GTK-based desktop environments
# (GNOME, Cinnamon, MATE) pick up the Nexus wallpaper as their default.
if [ -x /usr/bin/dconf ]; then
    dconf update || echo "WARNING: dconf update failed; GTK DE wallpaper defaults may not apply"
fi

# Add the plymouth hook to /etc/mkinitcpio.conf so installed systems (whose
# initramfs is generated from this file by Calamares) boot into the Nexus
# splash as well. The live ISO boot uses the mkinitcpio.conf.d/archiso.conf
# drop-in, which already contains the plymouth hook.
if [ -f /etc/mkinitcpio.conf ]; then
    sed -i 's/^HOOKS=(base /HOOKS=(base plymouth /' /etc/mkinitcpio.conf
fi

# Ensure the installed GRUB passes 'splash' (and quiet) so plymouth shows.
if [ -f /etc/default/grub ]; then
    sed -i 's/^GRUB_CMDLINE_LINUX_DEFAULT=.*/GRUB_CMDLINE_LINUX_DEFAULT="loglevel=3 quiet splash"/' /etc/default/grub
fi

# Rebuild all initramfs images now that the Nexus plymouth theme and
# /etc/plymouth/plymouthd.conf are in place. The initramfs generated during
# pacstrap was built before the profile airootfs was copied over, so it would
# otherwise not contain the plymouth hook/theme.
if [ -x /usr/bin/mkinitcpio ]; then
    mkinitcpio -P || echo "WARNING: mkinitcpio -P failed; plymouth may not be in the initramfs"
fi
