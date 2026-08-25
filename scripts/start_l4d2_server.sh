#!/bin/bash

# L4D2 Dedicated Server Startup Script

STEAM_USER="steamcmd"
L4D2_HOME="/opt/steamcmd/l4d2_server"

# Server configuration
HOSTNAME="L4D2 Server"
RCON_PASSWORD="changeme123"
SERVER_PORT="27015"
TV_PORT="27020"
MAP="c2m1_highway"
MAXPLAYERS="8"

# Validate setup
if [ ! -f "$L4D2_HOME/srcds_run" ]; then
  echo "Error: L4D2 server not found at $L4D2_HOME"
  echo "Run install_l4d2_server.sh first"
  exit 1
fi

echo "Starting L4D2 Dedicated Server..."
echo "  Hostname: $HOSTNAME"
echo "  Port: $SERVER_PORT"
echo "  Map: $MAP"
echo "  Max Players: $MAXPLAYERS"
echo ""

# Run server
su - "$STEAM_USER" <<EOF
cd "$L4D2_HOME"
./srcds_run -game left4dead2 \
    -console \
    -steam_dir /opt/steamcmd \
    -steamcmd_script /opt/steamcmd/update_script.txt \
    +runscript update_script.txt \
    +hostport $SERVER_PORT \
    +tv_port $TV_PORT \
    +hostname "$HOSTNAME" \
    +sv_password "" \
    +rcon_password "$RCON_PASSWORD" \
    +maxplayers $MAXPLAYERS \
    +map $MAP \
    +ip 0.0.0.0 \
    +port 27015 \
    +exec server.cfg
EOF
