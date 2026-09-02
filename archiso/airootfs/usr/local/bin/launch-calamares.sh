#!/bin/bash
# Launches the Calamares installer on the live desktop. Online-only install
# flow: pacstrap-based, uses the online settings_online.conf which
# ships the bootloader and desktop choosers plus the netinstall module.
# Requires a network during install and a published [nexus] repo (GitHub
# Releases). Installed into the ISO as an autostart entry so Calamares opens
# directly instead of a welcome/hello app.

main() {
    exec /usr/local/bin/calamares-online.sh
}

main "$@"
