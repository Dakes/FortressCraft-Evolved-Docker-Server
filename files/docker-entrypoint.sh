#!/bin/bash
set -euo pipefail

FCE_VOL=/FCE
LOAD_LATEST_SAVE="${LOAD_LATEST_SAVE:-true}"
GENERATE_NEW_SAVE="${GENERATE_NEW_SAVE:-false}"
WORLD_NAME="${SAVE_NAME:-""}"

mkdir -p "$FCE_VOL"
mkdir -p "$SAVES"
mkdir -p "$CONFIG"
mkdir -p "$MODS"
mkdir -p /opt/FCE/Default

if [[ "${UPDATE_ON_START:-true}" == "true" ]] || [[ ! -x /opt/FCE/FC_Linux_Universal.x86_64 ]]; then
  steamcmd \
    +@ShutdownOnFailedCommand 1 \
    +@NoPromptForPassword 1 \
    +force_install_dir /opt/FCE \
    +login anonymous \
    +app_update "$STEAM_ID" validate -beta "$BRANCH" \
    +quit
fi

#if [[ ! -f $CONFIG/rconpw ]]; then
  # Generate a new RCON password if none exists
  #pwgen 15 1 >"$CONFIG/rconpw"
#fi


if [[ ! -f $CONFIG/firstrun.ini ]]; then
  # Copy default settings if server-settings.json doesn't exist
  # cp "/opt/FCE/Default/Example Server Ini files/firstrun.ini" "$CONFIG/firstrun.ini"
  cp "/firstrun.ini" "$CONFIG/firstrun.ini"
  echo "copying default firstrun.ini"
fi

if [[ ! -f $CONFIG/serveroverrides.ini ]]; then
  # Copy default settings if server-settings.json doesn't exist
  # cp "/opt/FCE/Default/Example Server Ini files/serveroverrides.ini" "$CONFIG/serveroverrides.ini"
  cp "/serveroverrides.ini" "$CONFIG/serveroverrides.ini"
  echo "copying default serveroverrides.ini"
fi

sed -i "s/^RCONPort = .*/RCONPort = ${RCON_PORT}/" "$CONFIG/serveroverrides.ini"
sed -i "s/^ServerPort = .*/ServerPort = ${PORT}/" "$CONFIG/serveroverrides.ini"

cp "$CONFIG/serveroverrides.ini" /opt/FCE/Default/serveroverrides.ini
cp "$CONFIG/firstrun.ini" /opt/FCE/Default/firstrun.ini


if [[ "${UPDATE_MODS_ON_START:-false}" == "true" ]]; then
  /docker-update-mods.sh
fi

if [[ ! -x /opt/FCE/FC_Linux_Universal.x86_64 ]]; then
  echo "FortressCraft server binary not found after SteamCMD install: /opt/FCE/FC_Linux_Universal.x86_64" >&2
  exit 1
fi


# ... existing SteamCMD and config setup ...

# Ensure the log file exists for tailing
touch /FCE/Player.log
tail -f /FCE/Player.log &
TAIL_PID=$!

cd /opt/FCE/
./FC_Linux_Universal.x86_64 -batchmode &
FCE_PID=$!

# Function to handle graceful shutdown
graceful_shutdown() {
    echo "Sending shutdown command (FCQuit) to FCE server..."
    # Extract RCON password from config, default to 'Password'
    RCON_PASS=$(grep -i "^RCONPassword" "$CONFIG/serveroverrides.ini" | cut -d'=' -f2 | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' || echo "Password")

    # Create a temporary config for rconclt
    cat <<EOF > /tmp/rcon.conf
[fce]
host = 127.0.0.1
port = ${RCON_PORT}
passwd = ${RCON_PASS:-Password}
EOF

    # Use rconclt with the temporary config
    # We use '|| true' because FCE often closes the connection before rconclt finishes,
    # and we don't want the script to exit before the server finishes saving.
    rconclt -t 15 -c /tmp/rcon.conf fce "FCQuit" || echo "Note: rconclt timed out, but command was sent."

    rm /tmp/rcon.conf
    echo "Waiting for FCE server to finish saving and exit..."
    wait "$FCE_PID"
    echo "FCE server has stopped gracefully. Exiting."
    exit 0
}

# Trap SIGTERM (sent by docker stop/down)
trap 'graceful_shutdown' SIGTERM SIGINT

# Wait for the server process to exit
wait "$FCE_PID"
echo "FCE server has stopped."

# Clean up tailing process
kill "$TAIL_PID" || true
