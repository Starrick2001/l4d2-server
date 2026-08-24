# L4D2 Dedicated Server Setup

Scripts to install and run a Left 4 Dead 2 dedicated server.

## Prerequisites

- Linux (Ubuntu/Debian recommended)
- Root access
- 20GB+ disk space
- Port 27015 (game) and 27020 (SourceTV) available

## Installation

```bash
sudo ./install_l4d2_server.sh
```

This will:
1. Install 32-bit dependencies
2. Download SteamCMD
3. Create `steamcmd` user
4. Download L4D2 server files

## Configuration

Edit `server.cfg` to customize:
- Difficulty level
- Game mode (coop/versus/survival/scavenge)
- Max players
- Friendly fire settings
- RCON password

## Running Server

```bash
sudo ./start_l4d2_server.sh
```

Server runs in foreground. Logs go to `~/Steam/logs/`.

## Quick Commands

**Stop server:** Ctrl+C

**Connect via console:**
```
connect <server_ip>:27015
```

**RCON commands (from client):**
```
rcon_password "changeme123"
rcon "changelevel c2m1_highway"
rcon "say Welcome to server!"
```

## Map Rotation

Add to `server.cfg`:
```
mp_maplist "c1m1_hotel c1m2_streets c1m3_rooftop c1m4_atrium c2m1_highway"
mp_maplist_index 0
```

## Troubleshooting

**Port already in use:**
```bash
lsof -i :27015
```

**Check logs:**
```bash
tail -f /opt/steamcmd/l4d2_server/server_console.log
```

**Update server:**
```bash
sudo -u steamcmd /opt/steamcmd/steamcmd.sh +force_install_dir /opt/steamcmd/l4d2_server +login anonymous +app_update 222860 validate +quit
```

## Server Config Details

- `mp_gamemode` - Game mode selection
- `z_difficulty` - 0=Easy, 1=Normal, 2=Hard, 3=Impossible
- `sv_maxrate` - Max bandwidth per client (kbps)
- `friendly_fire` - Enable/disable (0/1)
- `ff_damage_reduction` - Damage multiplier for friendly fire
