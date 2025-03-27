microk8s helm install open5gs-upf2 /vagrant/charts/open5gs-upf -f /vagrant/configs/open5gs-ueransim/upf2-values.yaml -n open5gs


microk8s helm install open5gs-upf1 /vagrant/charts/open5gs-upf -f /vagrant/configs/open5gs-ueransim/upf1-values.yaml -n open5gs


microk8s helm upgrade --install open5gs /vagrant/charts/open5gs -n open5gs --create-namespace --values /vagrant/configs/open5gs-ueransim/5gSA-values.yaml

microk8s helm upgrade --install ueransim-gnb oci://registry-1.docker.io/gradiant/ueransim-gnb --version 0.2.6 --namespace open5gs --create-namespace --values /vagrant/configs/open5gs-ueransim/gnb-ues-values.yaml

microk8s kubectl get pods -n open5gs
microk8s kubectl get nodes

microk8s helm uninstall open5gs-upf1 -n open5gs
microk8s helm uninstall open5gs-upf2 -n open5gs
microk8s kubectl delete pod --all -n open5gs
microk8s kubectl delete all --all -n open5gs

microk8s kubectl get svc -n open5gs

microk8s kubectl get cm -n open5gs
microk8s kubectl describe cm -n open5gs <config-name>

microk8s helm dependency update



Check gnodeb log with:

```
kubectl -n open5gs logs deployment/ueransim-gnb
```

---

You have also deployed 2 ues. You can enter ues terminal with:

```
kubectl -n open5gs exec -ti deployment/ueransim-gnb-ues -- /bin/bash
```
There is a tun interface for each ue.
You can bind your application to the interface to test ue connectivity.
Example:

```
ping -I uesimtun0 gradiant.org
traceroute -i uesimtun0 gradiant.org
curl --interface uesimtun0 https://www.gradiant.org/
```

You can also deploy more ues connected to this gnodeb with gradiant/ueransim-ues chart:

```
helm install -n open5gs ueransim-ues gradiant/ueransim-ues --set gnb.hostname=ueransim-gnb
```
