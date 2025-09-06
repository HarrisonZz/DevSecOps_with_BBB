Vagrant.configure("2") do |config|

  # --- K3s Agent ---
  config.vm.define "k3s-agent" do |agent|
    agent.vm.box = "bento/debian-11"
    agent.vm.hostname = "k3s-agent"
    agent.vm.box_version = "202508.03.0"

    agent.vm.network "public_network"
    agent.vm.network "private_network", ip: "192.168.20.10"

    agent.vm.provider "vmware_desktop" do |vm|
      vm.cpus = "2"
      vm.memory = "2048"
    end
  end

  # --- K3s Server ---
  config.vm.define "k3s-server" do |server|
    server.vm.box = "bento/debian-11"
    server.vm.hostname = "k3s-server"
    server.vm.box_version = "202508.03.0"

    server.vm.network "public_network"
    server.vm.network "private_network", ip: "192.168.20.11"
  
    server.vm.provider "vmware_desktop" do |vm|
        vm.cpus = "2"
        vm.memory = "4096"
    end
    server.vm.provision "shell", name: "network-routes", inline: <<-SHELL
        set -euo pipefail
        sleep 3

        ETH2_INTERFACE="eth2"
        if ! ip route show | grep -q "192.168.6.0/24 via 192.168.20.1"; then
        echo "Adding route 192.168.6.0/24 via 192.168.20.1 dev $ETH2_INTERFACE"
        ip route add 192.168.6.0/24 via 192.168.20.1 dev $ETH2_INTERFACE
        
        echo "192.168.6.0/24 via 192.168.20.1 dev $ETH2_INTERFACE" >> /etc/systemd/network/99-k3s-routes.netdev
      fi
    SHELL

    server.vm.provision "shell", path: "scripts/k3s-server-setup.sh"
    
  end

end
