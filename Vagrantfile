# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure(2) do | global |
#  global.vm.box = "landregistry/centos"
  global.vm.box = "landregistry/centos"

  global.vm.provision "shell", inline: "sed -i -e 's,keepcache=0,keepcache=1,g' /etc/yum.conf"
  #Reenable the line below if the .yum folder is empty
  #global.vm.provision "shell", inline: 'sudo yum update -q -y'

  nodes = [
    {
      :name => 'A',
      :addr => '192.168.33.10',
      :role => 'master',
      :id => 1
    },
    {
      :name => 'B',
      :addr => '192.168.33.20',
      :role => 'slave',
      :id => 2
    },
    {
      :name => 'C',
      :addr => '192.168.33.30',
      :role => 'slave',
      :id => 3
    },
    {
      :name => 'controller',
      :addr => '192.168.33.40',
      :role => 'controller',
      :id => 4
    }
  ]

  nodes.each_with_index do | node, i |
    global.vm.define node[:name] do | config |
      config.vm.hostname = node[:name]
      config.vm.network :private_network,
        ip: node[:addr],
        virtualbox_inet: true
      config.vm.synced_folder ".yum", "/var/cache/yum"
      config.vm.provision "shell",
        inline: "/vagrant/install.sh #{node[:addr]} #{node[:role]} #{node[:id]}"
      config.vm.provider :virtualbox do |vb|
        vb.customize ['modifyvm', :id, '--memory', ENV['VM_MEMORY'] || 3072]
        vb.customize ['modifyvm', :id, '--natdnshostresolver1', 'on']
        vb.customize ['modifyvm', :id, '--natdnsproxy1', 'on']
        vb.customize ["modifyvm", :id, "--cpus", ENV['VM_CPUS'] || 4]
      end
    end
  end

end
