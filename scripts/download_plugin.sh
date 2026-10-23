#!/bin/bash

set -euo pipefail

if [[ $# -ne 1 || ! "${1:-}" =~ ^[0-9]+$ ]]; then
  echo "Usage: $0 <workshop-addon-id>" >&2
  exit 1
fi
ADDON_ID="$1"

STEAM_HOME="/opt/steamcmd"
L4D2_HOME="$STEAM_HOME/l4d2_server"
WORKSHOP_DIR="$L4D2_HOME/left4dead2/addons/workshop"

mkdir -p "$WORKSHOP_DIR"


FILE_URL=$(curl -fsS -X POST \
  "https://api.steampowered.com/ISteamRemoteStorage/GetPublishedFileDetails/v1/" \
  --data-urlencode "itemcount=1" \
  --data-urlencode "publishedfileids[0]=$ADDON_ID" |
  jq -r '.response.publishedfiledetails[0].file_url // empty')

if [[ -n "$FILE_URL" ]]; then
  curl -fL "$FILE_URL" -o "$WORKSHOP_DIR/${ADDON_ID}.vpk"
else
  echo "Steam did not provide a direct download URL for this addon." >&2
fi