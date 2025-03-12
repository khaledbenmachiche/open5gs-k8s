# Install snapd
package 'snapd' do
  action :install
end

# Ensure snapd service is running and enabled
service 'snapd' do
  action [:enable, :start]
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

# Wait for MicroK8s to be ready (with timeout)
execute 'ensure_microk8s_ready' do
  command 'microk8s status --wait-ready --timeout 120'
  not_if 'microk8s status | grep "microk8s is running"'
  retries 3
  retry_delay 30
end

# Create directory for join scripts
directory '/tmp/microk8s' do
  owner 'vagrant'
  group 'vagrant'
  mode '0755'
  action :create
end

# Fetch Kubernetes join command from Master node
bash 'get_join_command' do
  code <<-EOH
    set -e
    ssh -o StrictHostKeyChecking=no -o ConnectTimeout=10 -i /vagrant/.vagrant/machines/master/virtualbox/private_key vagrant@192.168.56.10 "microk8s add-node --format short" > /tmp/microk8s/join_command.sh
    chmod +x /tmp/microk8s/join_command.sh
  EOH
  not_if { File.exist?('/tmp/microk8s/join_command.sh') && `grep -c "192.168.56.10" /tmp/microk8s/join_command.sh`.to_i > 0 }
  notifies :run, 'bash[join_microk8s_cluster]', :immediately
end

# Extract and execute the join command
bash 'join_microk8s_cluster' do
  code <<-EOH
    join_command=$(grep "192.168.56.10" /tmp/microk8s/join_command.sh)
    if [ -n "$join_command" ]; then
      $join_command
      sleep 30  # Wait for join to complete
    else
      echo "No valid join command found"
      exit 1
    fi
  EOH
  action :nothing
  not_if 'microk8s status | grep "This node is part of the cluster"'
end