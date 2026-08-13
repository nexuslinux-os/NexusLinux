#!/bin/bash
cat > /etc/os-release <<'EOF'
NAME="Nexus Linux"
PRETTY_NAME="Nexus Linux"
ID=nexus
ID_LIKE=arch
BUILD_ID=rolling
ANSI_COLOR="38;2;23;147;209"
EOF
