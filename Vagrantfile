# -*- mode: ruby -*-
# vim: set ft=ruby :
home = ENV['HOME']
ENV["LC_ALL"] = "en_US.UTF-8"


Vagrant.configure(2) do |config|
  # ПЕРВАЯ ВИРТУАЛЬНАЯ МАШИНА
    config.vm.define "test-bash" do |server|
    # имя виртуальной машины
    server.vm.box = 'vedoff/centos-7-5' 
    server.vm.provider "virtualbox" do |vb|
      vb.name = "test-bash"
    end
    # hostname виртуальной машины
    server.vm.hostname = "test-bash"
    # настройки сети
    server.vm.network "private_network", ip: "192.168.56.210"
    server.vm.synced_folder ".", "/vagrant",  
          type: "rsync",
          rsync_auto: "true",
          rsync_exclude: [".git/",".vagrant/",".gitignore","Vagrantfile"]
          server.vm.provision "shell", path: "provision/timer-cgi.sh"
          server.vm.provision "shell", path: "provision/httpd-multi.sh"
    end
end