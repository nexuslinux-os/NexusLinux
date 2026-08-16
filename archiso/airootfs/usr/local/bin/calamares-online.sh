#!/bin/bash

main() {
    # Remove current keyring first, to complete initiate it
    sudo rm -rf /etc/pacman.d/gnupg
    # We are using this, because archlinux is signing the keyring often with a newly created keyring
    # This results into a failed installation for the user.
    # Installing archlinux-keyring fails due not being correctly signed
    # Mitigate this by installing the latest archlinux-keyring on the ISO, before starting the installation
    # The issue could also happen, when the installation does rank the mirrors and then a "faulty" mirror gets used
    # -Syy forces a full DB refresh so we never install against a stale database;
    # --needed skips the (already current) keyring packages.
    sudo pacman -Syy --needed --noconfirm archlinux-keyring nexus-keyring
    # Also populate the keys, before starting the Installer, to avoid above issue
    sudo pacman-key --init
    for _ring in nexus cachyos; do
        sudo pacman-key --populate archlinux "$_ring" \
            || echo "UYARI: $_ring anahtar halkasi populate edilemedi" >&2
    done
    # Also use timedatectl to sync the time with the hardware clock
    # There has been a bunch of reports, that the keyring was created in the future
    # Syncing appears to fix it
    timedatectl set-ntp true

    local progname="$(basename "$0")"
    local log="/home/liveuser/nexus-install.log"
    local mode="online"  # TODO: keep this line for now

    local SYSTEM=""

    if [ -d /sys/firmware/efi ]; then
        SYSTEM="UEFI SYSTEM"
    else
        SYSTEM="BIOS/MBR SYSTEM"
    fi

    local ISO_VERSION="$(cat /etc/version-tag)"
    echo "USING ISO VERSION: ${ISO_VERSION}"

    # nexus-calamares is already shipped on the ISO; do not reinstall it.
    # (A pacman -Sy here would fail: the local [nexus] repo path from the build
    # host does not exist on the live system.)

    # Apply Nexus Linux branding on top of the freshly installed Calamares config
    sudo cp -r /usr/share/nexus-calamares/branding/nexus /usr/share/calamares/branding/nexus
    sudo cp /usr/share/nexus-calamares/modules/shellprocess.conf /etc/calamares/modules/shellprocess.conf
    sudo cp /usr/share/nexus-calamares/modules/netinstall.yaml /etc/calamares/modules/netinstall.yaml
    sudo cp /usr/share/nexus-calamares/modules/packagechooser_desktop.conf /etc/calamares/modules/packagechooser_desktop.conf
    sudo cp /usr/share/nexus-calamares/modules/partition.conf /etc/calamares/modules/partition.conf
    sudo cp /usr/share/nexus-calamares/modules/unpackfs.conf /etc/calamares/modules/unpackfs.conf
    sudo sed -i 's/^branding: cachyos/branding: nexus/' /usr/share/calamares/settings_${mode}.conf
    sudo sed -i 's|branding: cachyos|branding: nexus|' /etc/calamares/settings.conf
    sudo sed -i 's/CachyOS/Nexus Linux/g' /etc/calamares/modules/welcome_online.conf
    sudo sed -i 's/CachyOS/Nexus Linux/g' /etc/calamares/modules/shellprocess-before-online.conf
    sudo sed -i 's/cachyos-${cpu}/nexus-${cpu}/' /etc/calamares/modules/users.conf
    sudo sed -i 's/cachyos-${cpu}/nexus-${cpu}/' /etc/calamares/modules/users-online.conf
    # Mark the default KDE Plasma desktop as recommended in the Desktop chooser.
    sudo sed -i 's|^      name: "Plasma Desktop"$|      name: "Plasma Desktop (Recommended)"|' /etc/calamares/modules/packagechooser_desktop.conf
    sudo sed -i 's|^  description: "KDE-Plasma Desktop - Simple by default, powerful when needed."$|  description: "KDE-Plasma Desktop - Simple by default, powerful when needed. (Recommended)"|' /etc/calamares/modules/netinstall.yaml

    # Get Hardware Informations
    inxi -F > "$log"

    cat <<EOF >> "$log"
########## $log by $progname
########## Started (UTC): $(date -u "+%x %X")
########## ISO version: $ISO_VERSION
########## System: $SYSTEM
EOF

    sudo cp "/usr/share/calamares/settings_${mode}.conf" /etc/calamares/settings.conf
    exec pkexec-wrapper calamares -D6 >> $log
}

main "$@"
