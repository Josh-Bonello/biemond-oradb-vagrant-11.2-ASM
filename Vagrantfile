# -*- mode: ruby -*-
# vi: set ft=ruby :

# Vagrantfile API/syntax version. Don't touch unless you know what you're doing!
VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|

  config.vm.define "dbasm" , primary: true do |dbasm|
    dbasm.vm.box = "centos-6.6-x86_64"
    dbasm.vm.box_url = "https://dl.dropboxusercontent.com/s/ijt3ppej789liyp/centos-6.6-x86_64.box"

    dbasm.vm.provider :vmware_fusion do |v, override|
      override.vm.box = "centos-6.6-x86_64-vmware"
      override.vm.box_url = "https://dl.dropboxusercontent.com/s/7ytmqgghoo1ymlp/centos-6.6-x86_64-vmware.box"
    end

    dbasm.vm.hostname = "dbasm.example.com"
    dbasm.vm.synced_folder ".", "/vagrant", :mount_options => ["dmode=777","fmode=777"]
    dbasm.vm.synced_folder "/Users/edwin/software", "/software"

    dbasm.vm.network :private_network, ip: "10.10.10.7"
#   dbasm.vm.network :private_network, ip: "192.168.33.100"

    dbasm.vm.provider :vmware_fusion do |vb|
      vb.vmx["numvcpus"] = "2"
      vb.vmx["memsize"] = "3548"
    end

    dbasm.vm.provider :virtualbox do |vb|
      vb.customize ["modifyvm"     , :id, "--memory", "3548"]
      vb.customize ["modifyvm"     , :id, "--name"  , "dbasm"]
      vb.customize ["modifyvm"     , :id, "--cpus"  , 2]
    end

    dbasm.vm.provision :shell, :inline => "ln -sf /vagrant/puppet/hiera.yaml /etc/puppet/hiera.yaml;rm -rf /etc/puppet/modules;ln -sf /vagrant/puppet/modules /etc/puppet/modules"

    dbasm.vm.provision :puppet do |puppet|
      puppet.manifests_path    = "puppet/manifests"
      puppet.module_path       = "puppet/modules"
      puppet.manifest_file     = "site.pp"
      puppet.options           = "--verbose --hiera_config /vagrant/puppet/hiera.yaml"

      puppet.facter = {
        "environment" => "development",
        "vm_type"     => "vagrant",
      }

    end

  end

end
