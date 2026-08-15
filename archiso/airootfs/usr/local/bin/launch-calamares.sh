#!/bin/bash
# Launches the Calamares installer on the live desktop. Currently only the
# normal (offline) ISO install flow is offered. The offline flow ships the
# bootloader and desktop choosers (see settings_offline.conf) — note the
# offline squashfs is Plasma-only, so a non-KDE pick needs a network.
# Installed into the ISO as an autostart entry so Calamares opens directly
# instead of a welcome/hello app.

main() {
    exec /usr/local/bin/calamares-offline.sh
}

main "$@"
