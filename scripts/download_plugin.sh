ADDON_ID="123456789" # Replace with the addon’s Workshop ID

FILE_URL=$(curl -fsS -X POST \
  "https://api.steampowered.com/ISteamRemoteStorage/GetPublishedFileDetails/v1/" \
  --data-urlencode "itemcount=1" \
  --data-urlencode "publishedfileids[0]=$ADDON_ID" |
  jq -r '.response.publishedfiledetails[0].file_url // empty')

if [[ -n "$FILE_URL" ]]; then
  curl -fL "$FILE_URL" -o "${ADDON_ID}.vpk"
else
  echo "Steam did not provide a direct download URL for this addon." >&2
fi