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
    unzip \
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

# Install Metamod:Source
echo "[*] Installing Metamod:Source..."
# su - "$STEAM_USER" << 'EOF'
cd "$L4D2_HOME/left4dead2"
mkdir -p addons

# Download latest Metamod:Source
# METAMOD_URL="https://mms.alliedmods.net/mmsdrop/1.11/mmsource-1.11.0-git1148-linux.tar.gz"
METAMOD_URL="https://github.com/alliedmodders/metamod-source/releases/download/1.12.0.1225/mmsource-1.12.0-git1225-linux.tar.gz"
wget -O /tmp/metamod.tar.gz "$METAMOD_URL" 2>/dev/null || \
    (echo "Failed to download Metamod from primary URL, trying fallback..." && \
     wget -O /tmp/metamod.tar.gz "https://mms.alliedmods.net/mmsdrop/1.11/mmsource-latest-linux.tar.gz" 2>/dev/null)

tar -xzf /tmp/metamod.tar.gz
rm /tmp/metamod.tar.gz
# EOF

# Install SourceMod
echo "[*] Installing SourceMod..."
# su - "$STEAM_USER" << 'EOF'
cd "$L4D2_HOME/left4dead2"

# Download latest SourceMod
# SOURCEMOD_URL="https://sm.alliedmods.net/smdrop/1.11/sourcemod-1.11.0-git6970-linux.tar.gz"
SOURCEMOD_URL="https://github.com/alliedmodders/sourcemod/releases/download/1.12.0.7250/sourcemod-1.12.0-git7250-linux.tar.gz"
wget -O /tmp/sourcemod.tar.gz "$SOURCEMOD_URL" 2>/dev/null || \
    (echo "Failed to download SourceMod from primary URL, trying fallback..." && \
     wget -O /tmp/sourcemod.tar.gz "https://sm.alliedmods.net/smdrop/1.11/sourcemod-latest-linux.tar.gz" 2>/dev/null)

tar -xzf /tmp/sourcemod.tar.gz
rm /tmp/sourcemod.tar.gz
# EOF

# Install L4DToolZ (lakwsh fork: maxplayers/tickrate unlock)
echo "[*] Installing L4DToolZ..."
cd "$L4D2_HOME/left4dead2"
L4DTOOLZ_VERSION="2.5.1"
L4DTOOLZ_URL="https://github.com/lakwsh/l4dtoolz/releases/download/${L4DTOOLZ_VERSION}/l4dtoolz-${L4DTOOLZ_VERSION}-main.zip"
wget -O /tmp/l4dtoolz.zip "$L4DTOOLZ_URL"
TMPDIR_L4DTOOLZ="$(mktemp -d)"
unzip -o -q /tmp/l4dtoolz.zip -d "$TMPDIR_L4DTOOLZ"
if [ -d "$TMPDIR_L4DTOOLZ/addons" ]; then
    cp -r "$TMPDIR_L4DTOOLZ/addons/." "$L4D2_HOME/left4dead2/addons/"
else
    mkdir -p "$L4D2_HOME/left4dead2/addons"
    cp -r "$TMPDIR_L4DTOOLZ/." "$L4D2_HOME/left4dead2/addons/"
fi
rm -rf "$TMPDIR_L4DTOOLZ" /tmp/l4dtoolz.zip
# Sanity check: metamod should pick this up as addons/metamod/l4dtoolz.vdf
if [ ! -f "$L4D2_HOME/left4dead2/addons/metamod/l4dtoolz.vdf" ]; then
    echo "WARNING: l4dtoolz.vdf not found after extract; check L4DTOOLZ_URL layout"
fi

# Install SuperVersus SourceMod plugin (Super Versus Reloaded, up to 32 players w/ L4DToolZ)
echo "[*] Installing SuperVersus..."
SUPERVERSUS_SP_URL="https://raw.githubusercontent.com/sappykun/l4d_superversus/main/l4d_superversus.sp"
SUPERVERSUS_SMX_FALLBACK_URL="https://raw.githubusercontent.com/Lt-Arashi/L4D2-Server-Plugins/Sm1.12_Test/addons/sourcemod/plugins/SuperVersus/SuperVersus.smx"
LEFT4DHOOKS_INC_URL="https://raw.githubusercontent.com/SilvDev/Left4DHooks/main/sourcemod/scripting/include/left4dhooks.inc"
mkdir -p "$L4D2_HOME/left4dead2/addons/sourcemod/plugins" \
         "$L4D2_HOME/left4dead2/addons/sourcemod/scripting/include" \
         "$L4D2_HOME/left4dead2/addons/sourcemod/scripting"
SUPERVERSUS_COMPILED=0
chmod +x "$L4D2_HOME/left4dead2/addons/sourcemod/scripting/spcomp" "$L4D2_HOME/left4dead2/addons/sourcemod/scripting/spcomp64" 2>/dev/null || true
if [ -x "$L4D2_HOME/left4dead2/addons/sourcemod/scripting/spcomp" ]; then
    SPCOMP="$L4D2_HOME/left4dead2/addons/sourcemod/scripting/spcomp"
else
    SPCOMP="$L4D2_HOME/left4dead2/addons/sourcemod/scripting/spcomp64"
fi
if wget -O "$L4D2_HOME/left4dead2/addons/sourcemod/scripting/l4d_superversus.sp" "$SUPERVERSUS_SP_URL" && \
   wget -O "$L4D2_HOME/left4dead2/addons/sourcemod/scripting/include/left4dhooks.inc" "$LEFT4DHOOKS_INC_URL" && \
   [ -x "$SPCOMP" ]; then
    cd "$L4D2_HOME/left4dead2/addons/sourcemod/scripting"
    if "$SPCOMP" l4d_superversus.sp -o ../plugins/l4d_superversus.smx; then
        SUPERVERSUS_COMPILED=1
    else
        echo "WARNING: spcomp compile failed, falling back to precompiled .smx"
    fi
    cd "$L4D2_HOME/left4dead2"
fi
if [ "$SUPERVERSUS_COMPILED" -ne 1 ]; then
    # Precompiled fallback (file may be named SuperVersus.smx upstream; normalize to l4d_superversus.smx)
    wget -O /tmp/superversus.smx "$SUPERVERSUS_SMX_FALLBACK_URL"
    cp /tmp/superversus.smx "$L4D2_HOME/left4dead2/addons/sourcemod/plugins/l4d_superversus.smx"
    rm -f /tmp/superversus.smx
fi
if [ ! -f "$L4D2_HOME/left4dead2/addons/sourcemod/plugins/l4d_superversus.smx" ]; then
    echo "ERROR: SuperVersus plugin install failed" >&2
    exit 1
fi

# Link server config
echo "[*] Linking server configuration..."
mkdir -p "$L4D2_HOME/left4dead2/cfg"
ln -sf "$SCRIPT_DIR/server.cfg" "$L4D2_HOME/left4dead2/cfg/server.cfg"
# Link SuperVersus config (versioned in repo, auto-created by plugin on first load if missing)
mkdir -p "$L4D2_HOME/left4dead2/cfg/sourcemod"
ln -sf "$SCRIPT_DIR/l4d_superversus.cfg" "$L4D2_HOME/left4dead2/cfg/sourcemod/l4d_superversus.cfg"

# Fix ownership (metamod/sourcemod/extracts above run as root, server runs as steam user)
chown -R "$STEAM_USER:$STEAM_USER" "$L4D2_HOME" "$STEAM_HOME"

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
