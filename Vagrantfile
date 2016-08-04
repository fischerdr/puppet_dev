# -*- mode: ruby -*-
# vi: set ft=ruby :
###############################################################################
# Vagrantfile for testing puppet development
#
# This is a pretty custom Vagrantfile that lets an instance be created on
# the spot (e.g. vagrant up foo) that isn't statically defined anywhere.
# It'll ask what box you want to use for <foo>.  There are caveats (assumes
# the last argument is a box name - vagrant destroy foo -f vs
# vagrant destroy -f foo), but hopefully usable enough for our purposes
###############################################################################
require 'yaml'
require 'json'
require_relative 'vagrant/vmethods'

# Print an error message and stop execution on handled errors
def handle_error(error_msg)
  puts "ERROR: #{error_msg}"
  exit
end

# Verify that config.yaml exists
root_dir = File.dirname(__FILE__)
vagrant_yaml_file = "#{root_dir}/config.yaml"
error_msg = "#{vagrant_yaml_file} does not exist"
handle_error(error_msg) unless File.exists?(vagrant_yaml_file)

vagrant_yaml = YAML.load_file(vagrant_yaml_file)
error_msg = "#{vagrant_yaml_file} exists, but is empty"
handle_error(error_msg) unless vagrant_yaml

# Vagrantfile API/syntax version. Don't touch unless you know what you're doing!
VAGRANTFILE_API_VERSION ||= "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  instances = get_indexed_vms(root_dir)
  (command, name) = get_arguments(ARGV)

  if command == "up" && !instances[name]
    instances[name] ||= ''
  end

  instances.each do |vname, box|
    config.vm.define vname do |node|
      exists = !box.empty?
      if command == "up" || exists
        box = get_box unless exists
        node.vm.box = box
        node.vm.network "private_network", type: "dhcp"
        node.vm.synced_folder ".", "/vagrant", id: "vagrant-root"
        node.ssh.shell = 'sh'

        if box =~ /windows/i
          provision = 'pe_windows.bat'
          mem = vagrant_yaml['windows_mem']
          cpus = vagrant_yaml['windows_cpu']

          node.vm.network :forwarded_port, guest: 3389, host: 3389, id: "rdp", auto_correct: true
          node.vm.network :forwarded_port, guest: 22, host: 2222, id: "ssh", auto_correct: true
          node.vm.guest = :windows
          node.windows.halt_timeout = 15
          node.vm.communicator = 'winrm'
          node.winrm.username = 'vagrant'
          node.winrm.password = 'vagrant'
        else
          provision = 'pe_agent.sh'
          mem = vagrant_yaml['linux_mem']
          cpus = vagrant_yaml['linux_cpu']

        end
        node.vm.hostname = "vagrant-#{rand(10**10)}.vagrant.vm" unless exists

        # If mem or cpu is specified for an instance matching this name, use
        # that value.
        if vagrant_yaml['instances'] and vagrant_yaml['instances'][vname]
          if vagrant_yaml['instances'][vname]['mem']
            mem = vagrant_yaml['instances'][vname]['mem']
          end

          if vagrant_yaml['instances'][vname]['cpu']
            cpus = vagrant_yaml['instances'][vname]['cpu']
          end
        end

      end


      ## Configure Virtualbox
      node.vm.provider :virtualbox do |vb|
        vb.customize ["modifyvm", :id, "--memory", mem]
        vb.customize ["modifyvm", :id, "--cpus", cpus]
        vb.customize ["setextradata", "global", "GUI/SuppressMessages", "all" ] if box =~ /windows/i
        vb.customize ["modifyvm", :id, "--ioapic", "on"] if cpus.to_i > 1
      end

      node.vm.provision :shell do |shell|
        shell.path = "vagrant/#{provision}"
        shell.args = [
          vagrant_yaml['puppet_master'],
          vagrant_yaml['pe_version'],
          vagrant_yaml['control_dir'],
          vagrant_yaml['modules_dir'],
        ].join(' ')
      end
    end
  end
end
