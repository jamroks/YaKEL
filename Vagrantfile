# -*- mode: ruby -*-
# vi: set ft=ruby :
require 'yaml'

ENV["LC_ALL"] = "en_US.UTF-8"
#sync_type = 'nfs'
VAGRANTFILE_API_VERSION = '2'

param = YAML.load_file(File.join(File.dirname(__FILE__), 'clustervars.yml'))

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  if Vagrant.has_plugin?('vagrant-hostmanager')
  config.hostmanager.enabled           = param['vagrant']['hostmanager']['enabled']
  config.hostmanager.manage_host       = param['vagrant']['hostmanager']['manage_host']
  config.hostmanager.manage_guest      = param['vagrant']['hostmanager']['manage_guest']
  config.hostmanager.ignore_private_ip = param['vagrant']['hostmanager']['private_ip_disabled']
  config.hostmanager.include_offline   = param['vagrant']['hostmanager']['offline_enabled']
  end
  if Vagrant.has_plugin?('landrush')
    config.landrush.enabled              = param['vagrant']['landrush']['enabled']
    config.landrush.tld                  = param['vagrant']['landrush']['tld']
    config.landrush.host_interface       = param['vagrant']['landrush']['interface']
    config.landrush.host_interface_class = param['vagrant']['landrush']['class']
    config.landrush.guest_redirect_dns   = param['vagrant']['landrush']['redirect_guest']
    config.landrush.host                   param['ingress']['edge']['route'], param['ingress']['edge']['address']
  end

  config.ssh.insert_key    = param['vagrant']['ssh']['insert_key']
  config.ssh.forward_agent = param['vagrant']['ssh']['forward_agent']
  config.ssh.shell         = param['vagrant']['ssh']['shell']
  config.vm.synced_folder '.', '/vagrant', id: 'vagrant-root', disabled: param['vagrant']['sync']['disabled']

  param['server']['worker']['nodes'].each do |node_id|

    next if !node_id['vagrant_enabled']

    config.vm.define node_id['nodename'] do |node|
      node.vm.box      = param['vagrant']['box']
      node.vm.hostname = node_id['fqdn']
      node.vm.network :private_network, ip: node_id['ip']
      node.hostmanager.aliases = node_id['aliases']
      node.vm.provider :virtualbox do |vb|
         vb.name = node_id[:vbname]
         vb.gui  = param['vagrant']['gui']['enbaled']
         vb.customize 'pre-boot', ["modifyvm", :id, "--memory", node_id['ram']]
         vb.customize 'pre-boot', ["modifyvm", :id, "--cpus", node_id['cpu']]
         vb.customize 'pre-boot', ["modifyvm", :id, "--natdnshostresolver1", param['vagrant']['vm_opts']['dnsresolver']]
         vb.customize 'pre-boot', ["modifyvm", :id, "--ioapic", param['vagrant']['vm_opts']['ioapic']]
      end
    end
  end
  
  param['server']['controlplane']['nodes'].each do |node_id|
    config.vm.define node_id['nodename'], primary: true do |controla|
      controla.vm.box      = param['vagrant']['box']
      controla.vm.hostname = node_id['fqdn']
      controla.vm.network :private_network, ip: node_id['ip']
      #controla.landrush.host node_id['ingress'], node_id['ip']
      # adding it, cause i'm changing the hostname inside the playbook
      #controla.landrush.host node_id['fqdn'], node_id['ip']
      controla.hostmanager.aliases = node_id['aliases']
      controla.vm.provider :virtualbox do |vb|
        vb.gui = param['vagrant']['gui']['enbaled']
        vb.customize 'pre-boot', ["modifyvm", :id, "--memory", node_id['ram']]
        vb.customize 'pre-boot', ["modifyvm", :id, "--cpus", node_id['cpu']]
        vb.customize 'pre-boot', ["modifyvm", :id, "--natdnshostresolver1", param['vagrant']['vm_opts']['dnsresolver']]
        vb.customize 'pre-boot', ["modifyvm", :id, "--ioapic", param['vagrant']['vm_opts']['ioapic']]
      end

  

      ansible_groups_vars = param['provisioner']['ansible_groups']
      ansible_hosts_vars  = param['provisioner']['ansible_host_vars']

      controla.vm.provision 'clusterplan', type: param['provisioner']['type'], run: 'once' do |ansible|
        ansible.verbose              = param['provisioner']['verbose']
        ansible.compatibility_mode   = "2.0"
        ansible.groups               = ansible_groups_vars
        ansible.host_vars            = ansible_hosts_vars
        ansible.limit                = param['provisioner']['limit']
        ansible.config_file          = param['provisioner']['config_file']
        ansible.tags                 = param['provisioner']['tags']['plan']
        ansible.playbook             = param['provisioner']['play']['clusterplan']
        ansible.extra_vars           = param['provisioner']['extra_vars']
      end
      controla.vm.provision 'clusterkube', type: param['provisioner']['type'] do |ansible|
        ansible.verbose                = param['provisioner']['verbose']
        ansible.compatibility_mode     = "2.0"
        ansible.groups                 = ansible_groups_vars
        ansible.host_vars              = ansible_hosts_vars
        ansible.limit                  = param['provisioner']['limit']
        ansible.config_file            = param['provisioner']['config_file']
        ansible.tags                   = param['provisioner']['tags']['kube']
        ansible.playbook               = param['provisioner']['play']['clusterkube']
        ansible.extra_vars             = param['provisioner']['extra_vars']
      end
      controla.vm.provision 'clusterapps', type: param['provisioner']['type'] do |ansible|
        ansible.verbose              = param['provisioner']['verbose']
        ansible.compatibility_mode     = "2.0"
        ansible.groups                 = ansible_groups_vars
        ansible.host_vars              = ansible_hosts_vars
        ansible.limit                  = param['provisioner']['limit']
        ansible.config_file            = param['provisioner']['config_file']
        ansible.tags                   = param['provisioner']['tags']['apps']
        ansible.playbook               = param['provisioner']['play']['clusterapps']
        ansible.extra_vars             = param['provisioner']['extra_vars']
      end
    end
  end

  config.trigger.after :destroy do |trigger|
    trigger.name = "Cleanup generated ressources"
    trigger.ignore = [:up, :halt, :resume, :provision, :reload]
    trigger.info = "Deleting resource folder ./provisioning/pki"
    trigger.run  = {inline: "rm -rf ./provisioning/pki && rm ./kubectl ./kubectl.kubeconfig"}
  end
end