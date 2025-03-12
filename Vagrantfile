MASTER_IPv4_ADDR = "192.168.56.10"

Vagrant.configure("2") do |config|
  config.vm.define "master" do |master|
    master.vm.box = "ubuntu/jammy64"
    master.vm.hostname = "microk8s-master"
    master.vm.network "private_network", ip: MASTER_IPv4_ADDR, hostname: true
    master.vm.network "forwarded_port", guest: 3000, host: 8081
    master.vm.provider "virtualbox" do |vb|
      vb.linked_clone = true
      vb.memory = "4096"
      vb.cpus = 4
    end
    master.vm.provision "chef_solo" do |chef|
      chef.arguments = "--chef-license accept"
      chef.cookbooks_path = "cookbooks"
      chef.add_recipe "microk8s_master"
    end
  end

  (1..2).each do |i|
    config.vm.define "worker#{i}" do |worker|
      worker.vm.box = "ubuntu/jammy64"
      worker.vm.hostname = "microk8s-worker#{i}"
      worker.vm.network "private_network", type: "dhcp"
      worker.vm.provider "virtualbox" do |vb|
        vb.linked_clone = true
        vb.memory = "2048"
        vb.cpus = 2
      end
      worker.vm.provision "chef_solo" do |chef|
        chef.arguments = "--chef-license accept"
        chef.cookbooks_path = "cookbooks"
        chef.add_recipe "microk8s_worker"
      end
    end
  end
end
