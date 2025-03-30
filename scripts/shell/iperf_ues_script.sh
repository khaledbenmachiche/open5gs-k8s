#!/bin/bash
set -euo pipefail

log() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] $*" >&2; }

if [[ $# -ne 1 ]]; then
    echo "Usage: $0 <number_of_interfaces | comma_separated_interfaces>"
    exit 1
fi

INPUT="$1"

# Generate interface list if the input is a number, otherwise use the provided list
if [[ "$INPUT" =~ ^[0-9]+$ ]]; then
    NUM_INTERFACES=$INPUT
    INTERFACES=()
    for ((i=0; i<NUM_INTERFACES; i++)); do
        INTERFACES+=("uesimtun$i")
    done
else
    IFS=',' read -ra INTERFACES <<< "$INPUT"
fi

log "Interfaces to test: ${INTERFACES[*]}"

for IFACE in "${INTERFACES[@]}"; do
    log "Running test on $IFACE"
    bash /vagrant/shell/iperf_ue_script.sh "$IFACE" &
    log "Test completed for $IFACE"
done

log "All iperf tests have been executed."
