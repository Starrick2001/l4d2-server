#!/bin/bash

set -e

# Set timezone to Asia/Ho_Chi_Minh non-interactively
export TZ=Asia/Ho_Chi_Minh
export DEBIAN_FRONTEND=noninteractive
ln -fs /usr/share/zoneinfo/Asia/Ho_Chi_Minh /etc/localtime
echo "Asia/Ho_Chi_Minh" | tee /etc/timezone

# Install SteamCMD and host L4D2 dedicated server

STEAM_USER="steamcmd"
STEAM_HOME="/opt/steamcmd"
L4D2_HOME="$STEAM_HOME/l4d2_server"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "=== L4D2 Dedicated Server Setup ==="

# Update system
echo "[*] Updating system packages..."
apt update
apt install -y curl wget software-properties-common
add-apt-repository -y multiverse

# Add 32-bit architecture support
dpkg --add-architecture i386
apt update

# Install en_US.UTF-8 locale
echo "[*] Installing en_US.UTF-8 locale..."
apt-get install -y locales
locale-gen en_US.UTF-8
update-locale LANG=en_US.UTF-8

# Install dependencies
echo "[*] Installing dependencies..."
apt-get update

echo steam steam/question select "I AGREE" | debconf-set-selections
echo steam steam/license note '' | debconf-set-selections

apt-get install -y \
    lib32gcc-s1 \
    lib32stdc++6 \
    libc6:i386 \
    libstdc++6:i386 \
    gcc-multilib \
    curl \
    wget \
    ca-certificates \
    vim \
    steamcmd

# Create steam user
echo "[*] Creating steam user..."
if ! id "$STEAM_USER" &>/dev/null; then
    useradd -m -s /bin/bash "$STEAM_USER"
    mkdir -p "$STEAM_HOME"
    chown -R "$STEAM_USER:$STEAM_USER" "$STEAM_HOME"
fi

# Create SteamCMD home directory
echo "[*] Setting up SteamCMD directory..."
mkdir -p "$STEAM_HOME"
chown -R "$STEAM_USER:$STEAM_USER" "$STEAM_HOME"

# Install L4D2 server
echo "[*] Installing L4D2 dedicated server..."
mkdir -p "$L4D2_HOME"
chown "$STEAM_USER:$STEAM_USER" "$L4D2_HOME"

su - "$STEAM_USER" << EOF
steamcmd +force_install_dir "$L4D2_HOME" \
    +login anonymous \
    +@sSteamCmdForcePlatformType windows \
    +app_update 222860 validate \
    +quit

steamcmd +force_install_dir "$L4D2_HOME" \
    +login anonymous \
    +@sSteamCmdForcePlatformType linux \
    +app_update 222860 validate \
    +quit
EOF

# Link server config
echo "[*] Linking server configuration..."
mkdir -p "$L4D2_HOME/left4dead2/cfg"
ln -s "$SCRIPT_DIR/server.cfg" "$L4D2_HOME/left4dead2/cfg/server.cfg"

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
