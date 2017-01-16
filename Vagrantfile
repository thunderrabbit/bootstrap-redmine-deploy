# Defines our Vagrant environment
# This file will create a VirtualBox machine from which we can 
# create a VPC
# create a subnet
# create a server in the subnet
# install redmine on the server
#
# Thanks to http://sysadmincasts.com/episodes/43-19-minutes-with-ansible-part-1-4
#
# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|

  # create mgmt node
  config.vm.define :mgmt do |mgmt_config|
      mgmt_config.vm.box = "ubuntu/trusty64"
      mgmt_config.vm.hostname = "mgmt"
      mgmt_config.vm.network :private_network, ip: "10.0.15.10"
      mgmt_config.vm.provider "virtualbox" do |vb|
        vb.memory = "256"
      end
      mgmt_config.vm.provision :shell, path: "bootstrap-mgmt.sh"
  end

end
