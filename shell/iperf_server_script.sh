#!/bin/bash
set -euo pipefail

log() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] $*" >&2; }

cleanup() {
    log "Arrêt du serveur iperf3..."
    pkill -P $$ || true
}
trap cleanup EXIT

log "Démarrage du serveur iperf3..."
iperf3 -s &
log "Serveur iperf3 lancé avec succès."

# Attendre indéfiniment pour éviter que le script ne se termine immédiatement
wait
