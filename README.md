# MicroK8s Open5GS & UERANSIM Deployment

This README provides step-by-step instructions for deploying Open5GS and UERANSIM components using MicroK8s and Helm.

## Prerequisites
- MicroK8s installed and configured
- Helm installed
- Access to the required Helm charts and configurations

## Deployment Steps

### 1. Install Open5GS User Plane Functions (UPFs)
```sh
microk8s helm install open5gs-upf2 /vagrant/charts/open5gs-upf -f /vagrant/configs/open5gs-ueransim/upf2-values.yaml -n open5gs

microk8s helm install open5gs-upf1 /vagrant/charts/open5gs-upf -f /vagrant/configs/open5gs-ueransim/upf1-values.yaml -n open5gs
```

### 2. Install Open5GS Core
```sh
microk8s helm upgrade --install open5gs /vagrant/charts/open5gs -n open5gs --create-namespace --values /vagrant/configs/open5gs-ueransim/5gSA-values.yaml
```

### 3. Install UERANSIM gNB
```sh
microk8s helm upgrade --install ueransim-gnb oci://registry-1.docker.io/gradiant/ueransim-gnb --version 0.2.6 --namespace open5gs --create-namespace --values /vagrant/configs/open5gs-ueransim/gnb-ues-values.yaml
```

### 4. Verify Deployment
```sh
microk8s kubectl get pods -n open5gs
microk8s kubectl get nodes
```

## Uninstalling Components
```sh
microk8s helm uninstall open5gs-upf1 -n open5gs
microk8s helm uninstall open5gs-upf2 -n open5gs
microk8s kubectl delete all --all -n open5gs
```

## Checking Services and ConfigMaps
```sh
microk8s kubectl get svc -n open5gs
microk8s kubectl get cm -n open5gs
microk8s kubectl describe cm -n open5gs <config-name>
```

## Retrieve Helm Manifest
```sh
microk8s helm get manifest open5gs-upf1 -n open5gs
```

## Updating Helm Dependencies
```sh
microk8s helm dependency update
```

## Configuring PFCP Hostnames
```yaml
{{- range .Values.config.upf.pfcp.hostnames }}
- address: {{ . }}
{{- end }}
```

## Network Performance Testing
Run `iperf3` test:
```sh
iperf3 -c 10.1.33.11 -B $(ip -4 addr show uesimtun0 | grep -oP '(?<=inet\s)\d+(\.\d+){3}')
```

## Checking gNodeB Logs
```sh
kubectl -n open5gs logs deployment/ueransim-gnb
```

## Accessing UE Terminals
To enter UE terminal:
```sh
kubectl -n open5gs exec -ti deployment/ueransim-gnb-ues -- /bin/bash
```
Each UE has a tun interface. To test connectivity:
```sh
ping -I uesimtun0 gradiant.org
traceroute -i uesimtun0 gradiant.org
curl --interface uesimtun0 https://www.gradiant.org/
```

## Deploying Additional UEs
To deploy more UEs connected to the gNB:
```sh
helm install -n open5gs ueransim-ues gradiant/ueransim-ues --set gnb.hostname=ueransim-gnb
```


Using a specific list of interfaces
Run the script with a comma-separated list of interfaces:

```bash
./iperf_multi_test.sh eth0,eth1,eth2
```

Using a number to auto-generate interface names
Run the script with a number, and it will generate eth0, eth1, ..., eth<N-1>:
```bash
./iperf_multi_test.sh 4
```
This will test eth0, eth1, eth2, eth3.

microk8s kubectl get networkchaos -n open5gs

kubectl apply -f upf-network-delay.yaml
microk8s kubectl delete networkchaos upf-network-delay -n open5gs


vagrant@microk8s-master:~$ microk8s helm upgrade --install grafana grafana/grafana   --create-namespace   --namespace monitoring   --values /vagrant/configs/monitoring/grafana_values.yaml
Release "grafana" does not exist. Installing it now.
NAME: grafana
LAST DEPLOYED: Sat Mar 29 19:47:45 2025
NAMESPACE: monitoring
STATUS: deployed
REVISION: 1
NOTES:
1. Get your 'admin' user password by running:

   kubectl get secret --namespace monitoring grafana -o jsonpath="{.data.admin-password}" | base64 --decode ; echo


2. The Grafana server can be accessed via port 80 on the following DNS name from within your cluster:

   grafana.monitoring.svc.cluster.local

   Get the Grafana URL to visit by running these commands in the same shell:
     export POD_NAME=$(kubectl get pods --namespace monitoring -l "app.kubernetes.io/name=grafana,app.kubernetes.io/instance=grafana" -o jsonpath="{.items[0].metadata.name}")
     kubectl --namespace monitoring port-forward $POD_NAME 3000

3. Login with the password from step 1 and the username: admin
#################################################################################
######   WARNING: Persistence is disabled!!! You will lose your data when   #####
######            the Grafana pod is terminated.                            #####
#################################################################################


vagrant@microk8s-master:~$ microk8s kubectl get secret --namespace monitoring grafana -o jsonpath="{.data.admin-password}" | base64 --decode ; echo
e9UJiOWAXCVwT4OihRzKlD8VKmFNxlcNLJqJAvaa

#
# This software is distributed under the Apache License 2.0,
# the text of which is available at https://github.com/Orange-OpenSource/towards5gs-helm/blob/main/LICENSE
# or see the "LICENSE" file for more details.
#
# Author: Abderaouf KHICHANE, Ilhem FAJJARI
# Software description: An open-source project providing Helm charts to deploy 5G components (Core + RAN) on top of Kubernetes
#
#
# Visit the project at https://github.com/Orange-OpenSource/towards5gs-helm
#

1. Run UE connectivity test by running these commands:
  helm --namespace free5gc test ueransim

If you want to run connectivity tests manually, follow:

1. Get the UE Pod name by running:
  export POD_NAME=$(kubectl get pods --namespace free5gc -l "component=ue" -o jsonpath="{.items[0].metadata.name}")

2. Check that uesimtun0 interface has been created by running these commands:
  kubectl --namespace free5gc logs $POD_NAME
  kubectl --namespace free5gc exec -it $POD_NAME -- ip address

3. Try to access internet from the UE by running:
  kubectl --namespace free5gc exec -it $POD_NAME -- ping -I uesimtun0 www.google.com
  kubectl --namespace free5gc exec -it $POD_NAME -- curl --interface uesimtun0 www.google.com
  kubectl --namespace free5gc exec -it $POD_NAME -- traceroute -i uesimtun0 www.google.com

Release notes (What's changed in this version):
- add the release notes
- add an initContainer to wait for the AMF to be ready
- enhance the handling of k8s NGAP service and network parameter
