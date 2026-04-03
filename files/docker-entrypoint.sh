#!/bin/bash
set -euxo pipefail

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

cp "$CONFIG/serveroverrides.ini" /opt/FCE/Default/serveroverrides.ini
cp "$CONFIG/firstrun.ini" /opt/FCE/Default/firstrun.ini


#if [[ ${UPDATE_MODS_ON_START:-} == "true" ]]; then
#  ./docker-update-mods.sh
#fi


if [[ $(id -u) = 0 ]]; then
  # Best-effort UID/GID remap for compatibility across base images.
  if command -v usermod >/dev/null 2>&1; then
    usermod -o -u "$PUID" FCE
  fi

  if command -v groupmod >/dev/null 2>&1; then
    groupmod -o -g "$PGID" FCE
  fi

  # Take ownership of fce data if running as root
  chown -R FCE:FCE "$FCE_VOL"
fi

if [[ ! -x /opt/FCE/FC_Linux_Universal.x86_64 ]]; then
  echo "FortressCraft server binary not found after SteamCMD install: /opt/FCE/FC_Linux_Universal.x86_64" >&2
  exit 1
fi


#sed -i '/write-data=/c\write-data=\/FCE/' /opt/FCE/config/config.ini
cd /opt/FCE/
./FC_Linux_Universal.x86_64 -batchmode
