# Open5GS & UERANSIM on MicroK8s

This repository contains configuration and deployment scripts for running an Open5GS 5G core network with UERANSIM (UE and RAN Simulator) on a MicroK8s Kubernetes cluster.

## Project Overview

This project enables the deployment of a complete 5G network environment using:
- **Open5GS**: A 5G Core implementation
- **UERANSIM**: A 5G UE (User Equipment) and RAN (Radio Access Network) simulator
- **MicroK8s**: A lightweight Kubernetes distribution
- **Helm**: Package manager for Kubernetes
- **Chaos Testing**: Network chaos testing capabilities for simulating network conditions
- **Monitoring**: Grafana dashboards for observability

## Prerequisites
- Ubuntu/Debian-based system (tested with Ubuntu 22.04)
- VirtualBox
- Vagrant
- Sufficient system resources (8GB+ RAM recommended)

## Quick Start

1. Clone this repository
2. Run `vagrant up` to create the Kubernetes cluster
3. Access the master node with `vagrant ssh master`

## Deployment Architecture

The deployment consists of:
- 1 Master node
- 3 Worker nodes with specific roles:
  - Worker1: UERANSIM components (2GB RAM, 2 CPUs)
  - Worker2: 5G control plane components (4GB RAM, 2 CPUs)
  - Worker3: 5G data plane components (2GB RAM, 2 CPUs)

## Deployment

The deployment is managed through Ansible playbooks, making it easy to provision the environment, deploy topologies, and clean up resources.

### Initial Provisioning

The initial provisioning happens automatically when you run `vagrant up`. It executes the following Ansible playbooks:

- Master node provisioning: `scripts/ansible/provisions/master_provision.yml`
- Worker nodes provisioning: `scripts/ansible/provisions/worker_provision.yml`

### Deploying Network Topologies

To deploy a network topology (e.g., topology1):

```sh
cd /vagrant
ansible-playbook scripts/ansible/topologies/test/topology1_provision.yml
```

You can verify the deployment with:

```sh
microk8s kubectl get pods -n open5gs
microk8s kubectl get nodes
```

## Administration

### Uninstalling Network Topologies
To uninstall a deployed network topology:

```sh
cd /vagrant
ansible-playbook scripts/ansible/topologies/test/uninstall_topology1.yml
```

For manual cleanup of individual components:
```sh
microk8s helm uninstall open5gs-upf1 -n open5gs
microk8s helm uninstall open5gs-upf2 -n open5gs
microk8s kubectl delete all --all -n open5gs
```

### Checking Services and ConfigMaps
```sh
microk8s kubectl get svc -n open5gs
microk8s kubectl get cm -n open5gs
microk8s kubectl describe cm -n open5gs <config-name>
```

## Configuration

## Testing and Validation

### Network Performance Testing
Run `iperf3` test:
```sh
iperf3 -c 10.1.33.11 -B $(ip -4 addr show uesimtun0 | grep -oP '(?<=inet\s)\d+(\.\d+){3}')
```

### Checking gNodeB Logs
```sh
kubectl -n open5gs logs deployment/ueransim-gnb
```

### Accessing UE Terminals
To enter UE terminal:
```sh
kubectl -n open5gs exec -ti deployment/ueransim-gnb-ues -- /bin/bash
```
Each UE has a tun interface. To test connectivity:
```sh
ping -I uesimtun0 8.8.8.8
traceroute -i uesimtun0 8.8.8.8
```

### Deploying Additional UEs
Additional UEs can be configured in the topology Ansible playbook. 

For manual deployment of more UEs connected to the gNB:
```sh
helm install -n open5gs ueransim-ues gradiant/ueransim-ues --set gnb.hostname=ueransim-gnb
```


## Network Testing Tools

### Interface Testing
Using a specific list of interfaces:
```bash
./iperf_multi_test.sh eth0,eth1,eth2
```

Using a number to auto-generate interface names:
```bash
./iperf_multi_test.sh 4  # Tests eth0, eth1, eth2, eth3
```

## Network Chaos Testing

### Setting Up Chaos Testing Environment
To set up the chaos testing environment:

```sh
cd /vagrant
ansible-playbook scripts/ansible/setups/chaos_setup.yml
```

### Managing Network Chaos Tests
View active chaos tests:
```sh
microk8s kubectl get networkchaos -n open5gs
```

Apply a network chaos configuration:
```sh
microk8s kubectl apply -f /vagrant/chaos/test/network_chaos_test_delay.yaml
```

Remove a network chaos configuration:
```sh
microk8s kubectl delete networkchaos upf-network-delay -n open5gs
```

## Monitoring

### Grafana Setup
```sh
microk8s helm upgrade --install grafana grafana/grafana \
  --create-namespace \
  --namespace monitoring \
  --values /vagrant/configs/monitoring/grafana_values.yaml
```

### Accessing Grafana
1. Forward the Grafana port:
```sh
export POD_NAME=$(kubectl get pods --namespace monitoring -l "app.kubernetes.io/name=grafana,app.kubernetes.io/instance=grafana" -o jsonpath="{.items[0].metadata.name}")
kubectl --namespace monitoring port-forward $POD_NAME 3000
```

2. Access Grafana at: http://localhost:3000
   - Username: admin
   - Password: Retrieve with:
```sh
microk8s kubectl get secret --namespace monitoring grafana -o jsonpath="{.data.admin-password}" | base64 --decode ; echo
```

> **Note**: The default Grafana admin password is stored in `grafana_admin_password.txt` as a backup.

## Directory Structure

- `charts/`: Helm charts for Open5GS and UERANSIM components
- `configs/`: Configuration files for various components
- `scripts/`: 
  - `ansible/`: 
    - `provisions/`: Initial setup playbooks for master and worker nodes
    - `topologies/`: Network topology deployment and cleanup playbooks
    - `setups/`: Additional setup playbooks (e.g., chaos testing)
  - `python/`: Python utility scripts
  - `shell/`: Shell helper scripts
- `chaos/`: Network chaos testing configurations

## Troubleshooting

If you encounter issues:

1. Check pod status: `microk8s kubectl get pods -n open5gs`
2. View pod logs: `microk8s kubectl logs -n open5gs <pod-name>`
3. Check endpoints: `microk8s kubectl get endpoints -n open5gs`
4. Examine service configuration: `microk8s kubectl describe svc -n open5gs <service-name>`

## License

This project uses components with various licenses:
- Open5GS: AGPL-3.0
- UERANSIM: GPL-3.0

## References

- [Open5GS Documentation](https://open5gs.org/open5gs/docs/)
- [UERANSIM GitHub](https://github.com/aligungr/UERANSIM)
- [MicroK8s Documentation](https://microk8s.io/docs/)

