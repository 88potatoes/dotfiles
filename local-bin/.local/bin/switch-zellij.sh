#!/bin/bash
export PATH="/run/current-system/sw/bin:/usr/local/bin:/usr/bin:/bin:~/.local/bin:$PATH"

CONFIG_FILE="$HOME/.local/bin/zellij-mapping.toml"

KEY=$1
SESSION=$(yq eval ".[\"$KEY\"]" "$CONFIG_FILE")
if [ "$SESSION" == "null" ] || [ -z "$SESSION" ]; then
    echo "No session mapped to key: $KEY"
    exit 1
fi

SOCKET_PATH=$(ls /tmp/mykitty* 2>/dev/null | head -n 1)
if [ -z "$SOCKET_PATH" ]; then
    echo "Error: No Kitty socket found in /tmp/"
    exit 1
fi
SOCKET="unix:$SOCKET_PATH"

# 2. Look for a TAB with the session name as its title
# We use jq to find the tab_id where the title matches our session
TAB_ID=$(kitty @ --to "$SOCKET" ls | jq -r ".[] | .tabs[] | select(.title == \"$SESSION\") | .id" | head -n 1)

if [ -n "$TAB_ID" ] && [ "$TAB_ID" != "null" ]; then
    kitty @ --to "$SOCKET" focus-tab --match "id:$TAB_ID"
else
    kitty @ --to "$SOCKET" launch --type=tab --tab-title "$SESSION" zellij attach -c "$SESSION"
fi
