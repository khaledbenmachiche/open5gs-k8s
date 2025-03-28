#!/bin/bash
# Getting IP addresses of open5gs-upf pods
ips=$(microk8s kubectl get pods -n open5gs --no-headers -o custom-columns="NAME:.metadata.name,IP:.status.podIP" | grep open5gs-upf* | awk '{print $2}')
