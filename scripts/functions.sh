#!/bin/bash
source "/home/steam/server/logging.sh"

log_cycle() {
  if [[ -f "$LOG_FILE" ]]; then
    cp "$LOG_FILE" "$SAVES_DIR/logs/AbioticFactor-$(date +%Y%m%d-%H%M%S).log"
    : > "$LOG_FILE"
  fi
}

rcon-call() {
  local args="$1"
  rcon-cli -c /home/steam/server/rcon.yml "$args"
}

steamcmd() { /opt/steamcmd/steamcmd.sh "$@"; }

link_dir() {
  local real=$1 link=$2
  mkdir -p "$real" "$(dirname "$link")"
  if [[ -d "$link" && ! -L "$link" ]]; then
    cp -rn "$link"/. "$real"/ 2>/dev/null || true
    rm -rf "$link"
  fi
  ln -sfn "$real" "$link"
}

local_buildid() {
  grep -Po '"buildid"\s+"\K\d+' "$SERVER_DIR/steamapps/appmanifest_${APP_ID}.acf" 2>/dev/null || echo 0
}

remote_buildid() {
  steamcmd +login anonymous +app_info_update 1 +app_info_print "$APP_ID" +quit 2>/dev/null \
  | awk -v b="\"$STEAM_BRANCH\"" '
      /"branches"/           { inb=1 }
      inb && $1==b           { f=1 }
      f && $1=="\"buildid\"" { gsub(/"/,"",$2); print $2; exit }' || true
}

update_server() {
  local beta_args=()
  [[ "$STEAM_BRANCH" != "public" ]] && beta_args=(-beta "$STEAM_BRANCH")

  for attempt in 1 2 3; do
    rc=0
    LogInfo "Installing afactor server into $SERVER_DIR"
    steamcmd \
        +@sSteamCmdForcePlatformType windows \
        +force_install_dir "$SERVER_DIR" \
        +login anonymous \
        +app_update "2857200" "${beta_args[@]}" validate \
        +quit || rc=$?
    (( rc == 0 )) && return 0
    LogWarn "SteamCMD failed (attempt $attempt/3, exit code $rc), retrying in 5 seconds..."
    tail -n 10 "$HOME/Steam/logs/stderr.txt" 2>/dev/null | sed 's/^/[steamcmd] /'
    sleep 5
  done
  LogError "SteamCMD failed 3 times"
  return 1
}

backup_server() {
  mkdir -p "$BACKUP_DIR"
  local name="$WORLD_NAME-$(date +%Y%m%d-%H%M%S).tar.gz"
  LogInfo "Backing up current server to $name"
  tar -czf "$BACKUP_DIR/$name" -C "$SAVES_DIR" .
  ls -1t "$BACKUP_DIR"/$WORLD_NAME-*.tar.gz 2>/dev/null \
    | tail -n +$((BACKUPS_TO_KEEP + 1)) | xargs -r rm -f
}

shutdown() {
  LogInfo "Shutting server down in 1 minute, please wait for server to stop gracefully."
  #rcon-call 'shutdown 1 "Shutting server down in 1 minute."'

  for ((i = 0; i < $SHUTDOWN_TIMEOUT; i++)); do
    kill -0 "$SERVER_PID" 2>/dev/null || break
    sleep 1
  done

  if pgrep -f 'AbioticFactorServer\.exe' >/dev/null; then
    LogWarn "Server still running after ${SHUTDOWN_TIMEOUT}s, killing Wine"
    wineserver -k || true
  fi
  wait "$SERVER_PID" 2>/dev/null || true
  LogInfo "Stopped"
  exit 0
}