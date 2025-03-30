#!/bin/bash
set -euo pipefail

log() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] $*" >&2; }

if [[ $# -ne 1 ]]; then
    echo "Usage: $0 <interface réseau>"
    exit 1
fi

INTERFACE="$1"

log "Récupération de l'adresse IP client sur l'interface $INTERFACE..."
CLIENT_IP=$(microk8s kubectl -n open5gs exec deployment/ueransim-gnb-ues -- \
    sh -c "ip -4 addr show $INTERFACE 2>/dev/null | grep -oP '(?<=inet\s)\d+(\.\d+){3}' || true")

if [[ -z "$CLIENT_IP" ]]; then
    log "Erreur: Impossible d'obtenir l'adresse IP sur $INTERFACE"
    exit 1
fi

log "Récupération de l'IP du réseau hôte..."
HOSTONLY_IP=$(ip -4 addr show enp0s8 | grep -oP '(?<=inet\s)\d+(\.\d+){3}')

if [[ -z "$HOSTONLY_IP" ]]; then
    log "Erreur: Impossible d'obtenir l'IP du réseau hôte."
    exit 1
fi

log "Adresse IP client: $CLIENT_IP"
log "Adresse IP hôte: $HOSTONLY_IP"

log "Lancement du test iperf3 client vers $HOSTONLY_IP..."
# Remove -ti flags that are causing the "Bad file descriptor" error
microk8s kubectl -n open5gs exec deployment/ueransim-gnb-ues -- \
    iperf3 -c "$HOSTONLY_IP" -B "$CLIENT_IP" -t 10 -P 10 -u --bandwidth 10M || {
    log "Erreur: Échec du test iperf3 client."
    exit 1
}

log "Test terminé avec succès."
