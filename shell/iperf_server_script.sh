#!/bin/bash
set -euo pipefail

log() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] $*" >&2; }

cleanup() {
    log "Arrêt du serveur iperf3..."
    pkill -P $$ || true
}
trap cleanup EXIT

LOG_FILE=""
if [[ $# -eq 1 ]]; then
    LOG_FILE="$1"
    log "Les logs seront enregistrés dans: $LOG_FILE"
fi

log "Démarrage du serveur iperf3..."
if [[ -n "$LOG_FILE" ]]; then
    # Redirect stdout and stderr to both terminal and log file
    iperf3 -s 2>&1 | tee "$LOG_FILE" &
else
    # Print only to terminal
    iperf3 -s &
fi

log "Serveur iperf3 lancé avec succès."

# Attendre indéfiniment pour éviter que le script ne se termine immédiatement
wait
