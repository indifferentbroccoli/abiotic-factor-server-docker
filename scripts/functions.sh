#!/bin/bash

APP_ID=2857200
WORLDS_DIR=$SERVER_DIR/AbioticFactor/Saved/SaveGames/Server/Worlds
BACKUP_DIR=$SERVER_DIR/backup

LogInfo()    { printf '%s\n' "$1"; }
LogWarn()    { printf '\033[1;33m%s\033[0m\n' "$1"; }
LogError()   { printf '\033[1;31m%s\033[0m\n' "$1"; }
LogSuccess() { printf '\033[1;32m%s\033[0m\n' "$1"; }
LogAction()  { printf '\033[1;36m==== %s ====\033[0m\n' "$1"; }

server_is_installed() {
  [ -f "$SERVER_DIR/AbioticFactorServer.exe" ]
}

install_server() {
  LogAction "Installing server (branch: $STEAM_BRANCH)"

  local args=(-app "$APP_ID" -os windows -osarch 64 -dir "$SERVER_DIR" -validate)

  if [ "$STEAM_BRANCH" != "public" ]; then
    args+=(-beta "$STEAM_BRANCH")
  fi

  if ! /depotdownloader/DepotDownloader "${args[@]}"; then
    LogError "Server install failed"
    return 1
  fi

  LogSuccess "Server installed"
}

backup_world() {
  if [ ! -d "$WORLDS_DIR/$WORLD_NAME" ]; then
    LogWarn "World '$WORLD_NAME' does not exist yet, skipping backup"
    return
  fi

  mkdir -p "$BACKUP_DIR"
  local name="$WORLD_NAME-$(date +%Y%m%d-%H%M%S).tar.gz"
  LogInfo "Backing up world to backup/$name"
  tar -czf "$BACKUP_DIR/$name" -C "$WORLDS_DIR/$WORLD_NAME" .

  ls -1t "$BACKUP_DIR/$WORLD_NAME"-*.tar.gz 2>/dev/null \
    | tail -n +$((BACKUPS_TO_KEEP + 1)) | xargs -r rm -f
}
