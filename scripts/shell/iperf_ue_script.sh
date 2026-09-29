#!/bin/bash
set -euo pipefail

log() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] $*" >&2; }

if [[ $# -ne 1 ]]; then
    echo "Usage: $0 <network_interface>"
    exit 1
fi

INTERFACE="$1"
UES_DEPLOYMENT="${UES_DEPLOYMENT:-ueransim-gnb1-ues}"

log "Getting client IP address on interface $INTERFACE..."
CLIENT_IP=$(microk8s kubectl -n open5gs exec "deployment/$UES_DEPLOYMENT" -- \
    sh -c "ip -4 addr show $INTERFACE 2>/dev/null | grep -oP '(?<=inet\s)\d+(\.\d+){3}' || true")

if [[ -z "$CLIENT_IP" ]]; then
    log "Error: could not get IP address on $INTERFACE"
    exit 1
fi

log "Getting host-only network IP..."
HOSTONLY_IP=$(ip -4 addr show enp0s8 | grep -oP '(?<=inet\s)\d+(\.\d+){3}')

if [[ -z "$HOSTONLY_IP" ]]; then
    log "Error: could not get host-only network IP."
    exit 1
fi

log "Client IP address: $CLIENT_IP"
log "Host IP address: $HOSTONLY_IP"

log "Running iperf3 client test against $HOSTONLY_IP..."
# Remove -ti flags that are causing the "Bad file descriptor" error
microk8s kubectl -n open5gs exec "deployment/$UES_DEPLOYMENT" -- \
    iperf3 -c "$HOSTONLY_IP" -B "$CLIENT_IP" -t 10 -P 10 -u --bandwidth 10M || {
    log "Error: iperf3 client test failed."
    exit 1
}

log "Test completed successfully."
