#!/bin/bash
set -euo pipefail

WORKSHOP_APP_ID="${WORKSHOP_APP_ID:-254200}"
WORKSHOP_ROOT="${WORKSHOP_ROOT:-/opt/FCE/.steamcmd-workshop}"
STEAMCMD_HOME="${STEAMCMD_HOME:-/FCE/.steamcmd}"
MOD_IDS_RAW="${MOD_IDS:-}"
MOD_UPDATE_STRICT="${MOD_UPDATE_STRICT:-false}"
STEAM_USERNAME="${STEAM_USERNAME:-}"
STEAM_PASSWORD="${STEAM_PASSWORD:-}"

mkdir -p "$MODS" "$WORKSHOP_ROOT" "$STEAMCMD_HOME"

steam_login_args() {
  if [[ -n "$STEAM_USERNAME" && -n "$STEAM_PASSWORD" ]]; then
    printf '%s\n' "$STEAM_USERNAME" "$STEAM_PASSWORD"
  else
    printf '%s\n' "anonymous"
  fi
}

collect_mod_ids() {
  if [[ -n "$MOD_IDS_RAW" ]]; then
    printf '%s\n' "$MOD_IDS_RAW" | tr ', ' '\n\n' | sed '/^$/d'
    return
  fi

  find "$MODS" -mindepth 1 -maxdepth 1 -type d -printf '%f\n' | grep -E '^[0-9]+$' | sort
}

download_mods() {
  local mod_id
  mapfile -t login_args < <(steam_login_args)
  local steamcmd_args=(
    +@ShutdownOnFailedCommand 1
    +@NoPromptForPassword 1
    +force_install_dir "$WORKSHOP_ROOT"
    +login
    "${login_args[@]}"
  )

  echo "Updating ${#mod_ids[@]} workshop mods"

  for mod_id in "${mod_ids[@]}"; do
    echo "Queueing workshop mod $mod_id"
    steamcmd_args+=(+workshop_download_item "$WORKSHOP_APP_ID" "$mod_id" validate)
  done

  steamcmd_args+=(+quit)

  if ! HOME="$STEAMCMD_HOME" steamcmd "${steamcmd_args[@]}"; then
    echo "Workshop download command failed" >&2
    return 1
  fi
}

sync_mod() {
  local mod_id="$1"
  local source_dir="$WORKSHOP_ROOT/steamapps/workshop/content/$WORKSHOP_APP_ID/$mod_id"
  local target_dir="$MODS/$mod_id"
  local staging_dir="${target_dir}.tmp"

  if [[ ! -d "$source_dir" ]]; then
    echo "Workshop content for mod $mod_id not found at $source_dir" >&2
    return 1
  fi

  rm -rf "$staging_dir"
  mkdir -p "$staging_dir"
  cp -a "$source_dir"/. "$staging_dir"/
  rm -rf "$target_dir"
  mv "$staging_dir" "$target_dir"
}

mapfile -t mod_ids < <(collect_mod_ids)

if [[ "${#mod_ids[@]}" -eq 0 ]]; then
  echo "No workshop mod IDs found in $MODS; skipping mod update."
  exit 0
fi

failed=0

if ! download_mods; then
  failed=1
  if [[ "$MOD_UPDATE_STRICT" == "true" ]]; then
    exit 1
  fi
fi

for mod_id in "${mod_ids[@]}"; do
  if ! sync_mod "$mod_id"; then
    failed=1
    if [[ "$MOD_UPDATE_STRICT" == "true" ]]; then
      exit 1
    fi
  fi
done

if [[ "$failed" -ne 0 ]]; then
  echo "One or more workshop mods failed to update. Continuing because MOD_UPDATE_STRICT=false." >&2
fi
