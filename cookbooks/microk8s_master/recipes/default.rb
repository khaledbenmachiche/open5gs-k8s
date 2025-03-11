# Install Snap package manager (if not already installed)
package 'snapd' do
  action :install
end

# Install MicroK8s using the dedicated Chef resource for snap packages
execute 'install_microk8s' do
  command 'snap install microk8s --classic'
  not_if 'snap list | grep microk8s'
end

# Add vagrant user to the microk8s group
group 'microk8s' do
  action :modify
  members 'vagrant'
  append true
end

# Ensure MicroK8s is ready before proceeding
execute 'wait_for_microk8s' do
  command 'microk8s status --wait-ready'
  retries 5
  retry_delay 10
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
  not_if { ::File.exist?('/home/vagrant/.kube/config') }
end

file '/home/vagrant/.kube/config' do
  owner 'vagrant'
  group 'vagrant'
  mode '0644'
end

# Enable essential MicroK8s addons
addons = %w[dns dashboard storage ingress]
addons.each do |addon|
  execute "enable_#{addon}" do
    command "microk8s enable #{addon}"
    not_if "microk8s status | grep -q #{addon}"
  end
end

# Helm Chart Values Files (Download or Use a Template)
open5gs_values = '/home/vagrant/open5gs-values.yaml'
ueransim_values = '/home/vagrant/ueransim-values.yaml'

remote_file open5gs_values do
  source 'https://gradiant.github.io/5g-charts/docs/open5gs-ueransim-gnb/5gSA-values.yaml'
  owner 'vagrant'
  group 'vagrant'
  mode '0644'
end

remote_file ueransim_values do
  source 'https://gradiant.github.io/5g-charts/docs/open5gs-ueransim-gnb/gnb-ues-values.yaml'
  owner 'vagrant'
  group 'vagrant'
  mode '0644'
end

# Deploy Open5GS using Helm
execute 'install_open5gs' do
  command "microk8s helm install open5gs oci://registry-1.docker.io/gradiant/open5gs --version 2.2.0 --namespace open5gs --create-namespace --values #{open5gs_values}"
  not_if 'microk8s kubectl get pods -n open5gs'
end

# Deploy UERANSIM gNodeB using Helm
execute 'install_ueransim' do
  command "microk8s helm install ueransim-gnb oci://registry-1.docker.io/gradiant/ueransim-gnb --version 0.2.6 --namespace open5gs --create-namespace --values #{ueransim_values}"
  not_if 'microk8s kubectl get pods -n open5gs'
end

# Verify Open5GS Deployment
execute 'check_open5gs' do
  command 'microk8s kubectl get pods -n open5gs'
end
