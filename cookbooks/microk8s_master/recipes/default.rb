# Install Snap package manager
package 'snapd' do
  action :install
end

# Install MicroK8s
execute 'install_microk8s' do
  command 'snap install microk8s --classic'
  not_if 'snap list | grep microk8s'
  notifies :modify, 'group[microk8s]', :immediately
end

# Add vagrant user to the microk8s group
group 'microk8s' do
  action :nothing
  members 'vagrant'
  append true
  notifies :run, 'execute[apply_group_membership]', :immediately
end

# Apply group membership without requiring logout/login
execute 'apply_group_membership' do
  command 'newgrp microk8s || true'
  action :nothing
  user 'vagrant'
end

# Ensure MicroK8s is ready before proceeding
execute 'wait_for_microk8s' do
  command 'microk8s status --wait-ready --timeout 120'
  retries 5
  retry_delay 10
  not_if 'microk8s status | grep "microk8s is running"'
end

# Create ~/.kube directory for storing Kubernetes configurations
directory '/home/vagrant/.kube' do
  owner 'vagrant'
  group 'vagrant'
  mode '0755'
  action :create
end

# Generate and set up Kubernetes config for MicroK8s
execute 'set_kubeconfig' do
  command 'microk8s config > /home/vagrant/.kube/config'
  creates '/home/vagrant/.kube/config'
  notifies :create, 'file[/home/vagrant/.kube/config]', :immediately
end

file '/home/vagrant/.kube/config' do
  owner 'vagrant'
  group 'vagrant'
  mode '0644'
  action :nothing
end

# Enable essential MicroK8s addons
%w[dns dashboard storage ingress].each do |addon|
  execute "enable_#{addon}" do
    command "microk8s enable #{addon}"
  end
end

# Create directory for values files
directory '/home/vagrant/5g-configs' do
  owner 'vagrant'
  group 'vagrant'
  mode '0755'
  action :create
end

# Helm Chart Values Files
values_files = {
  '/home/vagrant/5g-configs/open5gs-values.yaml' => 'https://gradiant.github.io/5g-charts/docs/open5gs-ueransim-gnb/5gSA-values.yaml',
  '/home/vagrant/5g-configs/ueransim-values.yaml' => 'https://gradiant.github.io/5g-charts/docs/open5gs-ueransim-gnb/gnb-ues-values.yaml'
}

values_files.each do |dest, src|
  remote_file dest do
    source src
    owner 'vagrant'
    group 'vagrant'
    mode '0644'
    retries 3
    retry_delay 5
    action :create
  end
end

# Create namespace for 5G components
execute 'create_namespace' do
  command 'microk8s kubectl create namespace open5gs --dry-run=client -o yaml | microk8s kubectl apply -f -'
  not_if 'microk8s kubectl get namespace | grep open5gs'
end

# Deploy Open5GS using Helm
bash 'install_open5gs' do
  code <<-EOH
    export KUBECONFIG=/home/vagrant/.kube/config
    sudo -E microk8s helm install open5gs oci://registry-1.docker.io/gradiant/open5gs \
      --version 2.2.0 \
      --namespace open5gs \
      --values /home/vagrant/5g-configs/open5gs-values.yaml \
      --timeout 10m
  EOH
  user 'vagrant'
  environment 'HOME' => '/home/vagrant'
  not_if 'microk8s helm list -n open5gs | grep open5gs'
end

# Deploy UERANSIM gNodeB using Helm
bash 'install_ueransim' do
  code <<-EOH
    export KUBECONFIG=/home/vagrant/.kube/config
    sudo -E microk8s helm install ueransim-gnb oci://registry-1.docker.io/gradiant/ueransim-gnb \
      --version 0.2.6 \
      --namespace open5gs \
      --values /home/vagrant/5g-configs/ueransim-values.yaml \
      --timeout 10m
  EOH
  user 'vagrant'
  environment 'HOME' => '/home/vagrant'
  not_if 'microk8s helm list -n open5gs | grep ueransim-gnb'
end

# Verify Open5GS and UERANSIM Deployment
bash 'check_deployment' do
  code <<-EOH
    echo "==== Open5GS and UERANSIM Deployment Status ===="
    echo "Open5GS Pods:"
    sudo -E microk8s kubectl get pods -n open5gs -l app.kubernetes.io/name=open5gs
    echo "UERANSIM Pods:"
    sudo -E microk8s kubectl get pods -n open5gs -l app.kubernetes.io/name=ueransim-gnb
    echo "Services:"
    sudo -E microk8s kubectl get services -n open5gs
  EOH
  user 'vagrant'
  environment 'HOME' => '/home/vagrant'
end