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

# Install L4DToolZ (Accelerator74, L4D2 Linux build)
echo "[*] Installing L4DToolZ..."
L4DTOOLZ_VERSION="2.2.0"
L4DTOOLZ_URL="https://github.com/Accelerator74/l4dtoolz/releases/download/${L4DTOOLZ_VERSION}/l4dtoolz-l4d2-linux-ef2a8df.tar.gz"
(
    L4DTOOLZ_ARCHIVE="$(mktemp)"
    trap 'rm -f "$L4DTOOLZ_ARCHIVE"' EXIT
    wget -O "$L4DTOOLZ_ARCHIVE" "$L4DTOOLZ_URL"
    tar -xzf "$L4DTOOLZ_ARCHIVE" -C "$L4D2_HOME/left4dead2"
)
if [ ! -f "$L4D2_HOME/left4dead2/addons/metamod/l4dtoolz.vdf" ]; then
    echo "ERROR: L4DToolZ install failed: l4dtoolz.vdf not found" >&2
    exit 1
fi

# Install SuperVersus 1.5.4 from the original AlliedModders post
# https://forums.alliedmods.net/showthread.php?p=830069
# Compile the official source with the installed SourceMod compiler.
echo "[*] Installing SuperVersus..."
SUPERVERSUS_SOURCE_URL="https://forums.alliedmods.net/attachment.php?attachmentid=54755"
(
    cd "$L4D2_HOME/left4dead2/addons/sourcemod/scripting"
    SUPERVERSUS_TMP="$(mktemp -d)"
    trap 'rm -rf "$SUPERVERSUS_TMP"' EXIT
    mkdir -p ../plugins
    if wget -O "$SUPERVERSUS_TMP/l4d_superversus.sp" "$SUPERVERSUS_SOURCE_URL"; then
        SPCOMP="./spcomp"
        if [ -f ./spcomp64 ]; then
            SPCOMP="./spcomp64"
        fi
        chmod +x "$SPCOMP"
        "$SPCOMP" "$SUPERVERSUS_TMP/l4d_superversus.sp" -i include -o "$SUPERVERSUS_TMP/l4d_superversus.smx"
        if [ ! -s "$SUPERVERSUS_TMP/l4d_superversus.smx" ]; then
            echo "ERROR: SuperVersus compilation produced no plugin" >&2
            exit 1
        fi
        install -m 644 "$SUPERVERSUS_TMP/l4d_superversus.sp" ./l4d_superversus.sp
        install -m 644 "$SUPERVERSUS_TMP/l4d_superversus.smx" ../plugins/l4d_superversus.smx
    else
        echo "WARNING: SuperVersus download failed; using bundled l4d_superversus.smx" >&2
        SUPERVERSUS_FALLBACK="$SCRIPT_DIR/../l4d_superversus.smx"
        if [ ! -s "$SUPERVERSUS_FALLBACK" ]; then
            echo "ERROR: Bundled SuperVersus plugin is missing or empty: $SUPERVERSUS_FALLBACK" >&2
            exit 1
        fi
        install -m 644 "$SUPERVERSUS_FALLBACK" ../plugins/l4d_superversus.smx
    fi
)

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
echo "  ./srcds_run -game left4dead2 -console -autoupdate \\"
echo "    +hostport 27015 +sv_search_key \\\"yourkey\\\" +map c1m1_hotel"
echo ""
echo "Or use the startup script created at: $SCRIPT_DIR/start_l4d2_server.sh"
