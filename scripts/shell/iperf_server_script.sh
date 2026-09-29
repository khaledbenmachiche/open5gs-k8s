#!/bin/bash
set -euo pipefail

log() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] $*" >&2; }

cleanup() {
    log "Stopping iperf3 server..."
    pkill -P $$ || true
}
trap cleanup EXIT

LOG_FILE=""
if [[ $# -eq 1 ]]; then
    LOG_FILE="$1"
    log "Logs will be written to: $LOG_FILE"
fi

log "Starting iperf3 server..."
if [[ -n "$LOG_FILE" ]]; then
    # Redirect stdout and stderr to both terminal and log file
    iperf3 -s --json --logfile "$LOG_FILE" &
else
    # Print only to terminal
    iperf3 -s &
fi

log "iperf3 server started successfully."

# Wait indefinitely so the script does not exit immediately
wait
