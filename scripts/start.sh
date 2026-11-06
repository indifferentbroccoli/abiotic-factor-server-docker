#!/bin/bash
source /home/steam/server/functions.sh

cd "$SERVER_DIR" || exit 1

args=(
  -log
  -newconsole
  -useperfthreads
  -NoAsyncLoadingThread
  -tcp
  -PORT=7777
  -QUERYPORT=27015
  -MaxServerPlayers="$MAX_PLAYERS"
  -SteamServerName="$SERVER_NAME"
  -WorldSaveName="$WORLD_NAME"
)

if [ -n "$MODS" ]; then
  args+=(-Mods="$MODS")
fi

LogAction "Starting server"
LogInfo "Arguments: ${args[*]}"

if [ -n "$SERVER_PASSWORD" ]; then
  args+=(-ServerPassword="$SERVER_PASSWORD")
fi
if [ -n "$MODIO_TOKEN" ]; then
  args+=(-ModioToken="$MODIO_TOKEN")
fi

exec xvfb-run --auto-servernum wine AbioticFactorServer.exe "${args[@]}"
