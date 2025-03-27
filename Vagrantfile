MASTER_IPv4_ADDR = "192.168.56.10"

WORKERS = [
  { id: 1, memory: 2048, cpus: 2, role: "ueransim" },
  { id: 2, memory: 4096, cpus: 2, role: "control_plane" },
  { id: 3, memory: 2048, cpus: 2, role: "data_plane" }
]

Vagrant.configure("2") do |config|
  config.vm.define "master" do |master|
    master.vm.box = "ubuntu/jammy64"
    master.vm.hostname = "microk8s-master"
    master.vm.network "private_network", ip: MASTER_IPv4_ADDR, hostname: true
    master.vm.network "forwarded_port", guest: 3000, host: 8081
    master.vm.provider "virtualbox" do |vb|
      vb.linked_clone = true
      vb.memory = "2048"
      vb.cpus = 2
    end
    master.vm.provision "ansible_local" do |ansible|
      ansible.playbook = "ansible/master_provision.yml"
      ansible.install = true
      ansible.install_mode = "pip"
      ansible.version = "latest"
    end
  end

  WORKERS.each do |worker_config|
    config.vm.define "worker#{worker_config[:id]}" do |worker|
      worker.vm.box = "ubuntu/jammy64"
      worker.vm.hostname = "microk8s-worker#{worker_config[:id]}"
      worker.vm.network "private_network", type: "dhcp"
      worker.vm.provider "virtualbox" do |vb|
        vb.linked_clone = true
        vb.memory = worker_config[:memory].to_s
        vb.cpus = worker_config[:cpus]
      end
      worker.vm.provision "ansible_local" do |ansible|
        ansible.playbook = "ansible/worker_provision.yml"
        ansible.install_mode = "pip"
        ansible.version = "latest"
        ansible.install = true
        ansible.extra_vars = {
          "master_address" => MASTER_IPv4_ADDR,
          "worker_role" => worker_config[:role],
          "worker_hostname" => "microk8s-worker#{worker_config[:id]}"
        }
      end

      if worker_config[:id] == WORKERS.last[:id]
        worker.vm.provision "shell", inline: <<-SHELL
          echo "Final provisioning step on master node..."
          ssh -o StrictHostKeyChecking=no -o ConnectTimeout=10 \
          -i /vagrant/.vagrant/machines/master/virtualbox/private_key \
          vagrant@#{MASTER_IPv4_ADDR} "ansible-playbook /vagrant/ansible/topology_provision.yml"
        SHELL
      end

    end
  end
end
