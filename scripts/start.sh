#!/bin/bash
source "/home/steam/server/logging.sh"
source "/home/steam/server/functions.sh"
set -euo pipefail

SERVER_PID=""
TAIL_PID=""

trap shutdown SIGTERM SIGINT

backup_server

launch=(wine $SERVER_DIR/AbioticFactorServer.exe
    -log -newconsole -useperfthreads -NoAsyncLoadingThread
    -MaxServerPlayers=$MAX_PLAYERS -PORT=7777 -QUERYPORT=27015
    -tcp -ServerPassword=$SERVER_PASSWORD -SteamServerName=$SERVER_NAME
    -WorldSaveName=$WORLD_NAME)

[[ -n "${MODS:-}" ]]        && launch+=("-Mods=${MODS}")
[[ -n "${MODIO_TOKEN:-}" ]] && launch+=("-ModioToken=${MODIO_TOKEN}")

if command -v xvfb-run >/dev/null 2>&1; then
  launch=(xvfb-run --auto-servernum "${launch[@]}")
else
  LogInfo "Xvfb not installed, launching without a virtual display"
fi

LogInfo "Starting: ${launch[*]}"
cd "$SERVER_DIR"
"${launch[@]}" 2>&1 &
SERVER_PID=$!

set +e
wait "$SERVER_PID"
status=$?
set -e

LogInfo "Server exited with status $status"
kill "$TAIL_PID" 2>/dev/null || true
exit "$status"