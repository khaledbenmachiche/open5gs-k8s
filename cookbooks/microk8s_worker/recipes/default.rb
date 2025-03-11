# Ensure APT cache is updated
execute 'update_apt_cache' do
  command 'apt update'
end

# Install snapd
package 'snapd' do
  action :install
end

# Ensure snapd service is running and enabled
service 'snapd' do
  action [:enable, :start]
end

# Install MicroK8s via snap
execute 'install_microk8s' do
  command 'snap install microk8s --classic'
  not_if 'snap list | grep microk8s'
end

# Add vagrant user to microk8s group
execute 'add_vagrant_to_microk8s' do
  command 'usermod -aG microk8s vagrant'
end

# Ensure MicroK8s is running
execute 'ensure_microk8s_ready' do
  command 'microk8s status --wait-ready'
  not_if { File.exist?('/var/snap/microk8s/current/var/lock/cni') }
end

# Fetch Kubernetes join command from Master node
execute 'get_join_command' do
  command 'ssh -o StrictHostKeyChecking=no -o ConnectTimeout=10 -i /vagrant/.vagrant/machines/master/virtualbox/private_key vagrant@192.168.56.10 "microk8s add-node --format short" > /tmp/join_command.sh'
  not_if { File.exist?('/tmp/join_command.sh') }
end

# Extract and execute the join command
execute 'join_microk8s_cluster' do
  command "bash -c 'grep \"192.168.56.10\" /tmp/join_command.sh | bash'"
  not_if 'microk8s status | grep "Node"'
end