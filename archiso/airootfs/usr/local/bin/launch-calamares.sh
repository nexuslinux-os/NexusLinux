#!/bin/bash
# Launches the Calamares installer on the live desktop. Currently only the
# normal (offline) ISO install flow is offered: no online variant, no desktop
# chooser. Installed into the ISO as an autostart entry so Calamares opens
# directly instead of a welcome/hello app.

main() {
    exec /usr/local/bin/calamares-offline.sh
}

main "$@"
