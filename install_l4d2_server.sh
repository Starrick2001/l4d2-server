#!/bin/bash

set -e

# Install SteamCMD and host L4D2 dedicated server

STEAM_USER="steamcmd"
STEAM_HOME="/opt/steamcmd"
L4D2_HOME="$STEAM_HOME/l4d2_server"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "=== L4D2 Dedicated Server Setup ==="

# Update system
echo "[*] Updating system packages..."
apt-get update
apt-get install -y curl wget software-properties-common

# Add 32-bit architecture support
dpkg --add-architecture i386

# Install dependencies
echo "[*] Installing dependencies..."
apt-get update
apt-get install -y \
    lib32gcc-s1 \
    lib32stdc++6 \
    libc6:i386 \
    libstdc++6:i386 \
    curl \
    wget \
    ca-certificates

# Create steam user
echo "[*] Creating steam user..."
if ! id "$STEAM_USER" &>/dev/null; then
    useradd -m -s /bin/bash "$STEAM_USER"
    mkdir -p "$STEAM_HOME"
    chown -R "$STEAM_USER:$STEAM_USER" "$STEAM_HOME"
fi

# Download SteamCMD
echo "[*] Downloading SteamCMD..."
mkdir -p "$STEAM_HOME"
cd "$STEAM_HOME"
curl -sqL "https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz" | tar xz

# Set permissions
chown -R "$STEAM_USER:$STEAM_USER" "$STEAM_HOME"

# Install L4D2 server
echo "[*] Installing L4D2 dedicated server..."
mkdir -p "$L4D2_HOME"
chown "$STEAM_USER:$STEAM_USER" "$L4D2_HOME"

su - "$STEAM_USER" << EOF
cd "$STEAM_HOME"
./steamcmd.sh +force_install_dir "$L4D2_HOME" \
    +login anonymous \
    +@sSteamCmdForcePlatformType windows \
    +app_update 222860 validate \
    +quit

./steamcmd.sh +force_install_dir "$L4D2_HOME" \
    +login anonymous \
    +@sSteamCmdForcePlatformType linux \
    +app_update 222860 validate \
    +quit
EOF

# Copy server config
echo "[*] Copying server configuration..."
mkdir -p "$L4D2_HOME/left4dead2/cfg"
cp "$SCRIPT_DIR/server.cfg" "$L4D2_HOME/left4dead2/cfg/server.cfg"
chown "$STEAM_USER:$STEAM_USER" "$L4D2_HOME/left4dead2/cfg/server.cfg"

echo "[*] Installation complete!"
echo ""
echo "=== Server Configuration ==="
echo "Server directory: $L4D2_HOME"
echo ""
echo "To run server, use:"
echo "  su - $STEAM_USER"
echo "  cd $L4D2_HOME"
echo "  ./srcds_run -game left4dead2 -console -autoupdate \\\"
echo "    +hostport 27015 +sv_search_key \\\"yourkey\\\" +map c1m1_hotel"
echo ""
echo "Or use the startup script created at: $SCRIPT_DIR/start_l4d2_server.sh"
