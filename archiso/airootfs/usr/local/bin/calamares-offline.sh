#!/usr/bin/env bash
set -euo pipefail

main() {
    local progname="$(basename "$0")"
    local log="/home/liveuser/nexus-install.log"
    local mode="offline"

    local SYSTEM=""

    if [ -d /sys/firmware/efi ]; then
        SYSTEM="UEFI SYSTEM"
    else
        SYSTEM="BIOS/MBR SYSTEM"
    fi

    local ISO_VERSION="$(cat /etc/version-tag)"
    echo "USING ISO VERSION: ${ISO_VERSION}"

    # Offline install: use the Calamares version already shipped on the ISO.
    # No pacman -Sy here: the offline variant must work without a network.

    # Apply Nexus Linux branding on top of the freshly installed Calamares config
    sudo cp -r /usr/share/nexus-calamares/branding/nexus /usr/share/calamares/branding/nexus
    sudo cp /usr/share/nexus-calamares/modules/shellprocess.conf /etc/calamares/modules/shellprocess.conf
    sudo cp /usr/share/nexus-calamares/modules/netinstall.yaml /etc/calamares/modules/netinstall.yaml
    sudo cp /usr/share/nexus-calamares/modules/packagechooser_desktop.conf /etc/calamares/modules/packagechooser_desktop.conf
    sudo cp /usr/share/nexus-calamares/modules/partition.conf /etc/calamares/modules/partition.conf
    sudo cp /usr/share/nexus-calamares/modules/unpackfs.conf /etc/calamares/modules/unpackfs.conf
    # Nexus offline settings: adds the bootloader + desktop choosers and the
    # netinstall module to the offline sequence (see settings_offline.conf).
    sudo sed -i 's|branding: cachyos|branding: nexus|' /etc/calamares/settings.conf
    sudo sed -i 's/CachyOS/Nexus Linux/g' /etc/calamares/modules/welcome.conf
    sudo sed -i 's/cachyos-${cpu}/nexus-${cpu}/' /etc/calamares/modules/users.conf

    # Get Hardware Informations
    inxi -F > "$log"

    cat <<EOF >> "$log"
########## $log by $progname
########## Started (UTC): $(date -u "+%x %X")
########## ISO version: $ISO_VERSION
########## System: $SYSTEM
EOF

    sudo cp "/usr/share/nexus-calamares/modules/settings_${mode}.conf" /etc/calamares/settings.conf
    exec pkexec-wrapper calamares -D6 >> $log
}

main "$@"
