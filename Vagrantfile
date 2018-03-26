# -*- mode: ruby -*-
# vi: set ft=ruby :
Vagrant::DEFAULT_SERVER_URL.replace('https://vagrantcloud.com')
## Define some app-specific stuff to be used later during provisioning: ##
app = {
  appname: 'vagrant',
  appdomain: 'vagrant.test',
  appshortname: 'VAG',
  dbname: 'vagrant',
  dbuser: 'vagrant',
  dbpassword: 'pass',
  dbrootpassword: 'pass',
  dbtype: 'mysql', # 'mysql' or 'postgresql',
  box_memory: 4096
}
# ansible_verbosity = 'vvvv'
##########################################################################

#Fix for people with strange locale settings
ENV.keys.each {|k| k.start_with?('LC_') && ENV.delete(k)}

def host_box_is_unixy?
  (RUBY_PLATFORM !~ /cygwin|mswin|mingw|bccwin|wince|emx/)
end

Vagrant.configure(2) do |config|

  # Ssh
  config.ssh.insert_key    = true
  config.ssh.username      = 'vagrant'
  config.ssh.forward_agent = true

  #VM
  config.vm.box            = "bento/ubuntu-17.10"
  config.vm.hostname       = app[:appdomain]
  config.vm.network        'private_network', type: 'dhcp'

  config.vm.synced_folder '.', '/vagrant',
    type: 'nfs',
    mount_options: ['nolock', 'actimeo=1', 'fsc']

  # Vm - Provider - Virtualbox
  config.vm.provider 'virtualbox' # Force provider
  config.vm.provider :virtualbox do |virtualbox|
    virtualbox.name   = app[:appname]
    virtualbox.memory = app[:box_memory]
    virtualbox.customize ['modifyvm', :id, '--natdnshostresolver1', 'on']
    virtualbox.customize ['modifyvm', :id, '--natdnsproxy1', 'on']
  end

  # Vm - Provision - Dotfiles
  for dotfile in ['.ssh/config', '.gitconfig', '.gitignore', '.composer/auth.json']
    if File.exists?(File.join(Dir.home, dotfile)) then
      config.vm.provision dotfile, type: 'file', run: 'always' do |file|
        file.source      = '~/' + dotfile
        file.destination = '/home/' + config.ssh.username + '/' + dotfile
      end
    end
  end

  verbosity_arg = if defined? ansible_verbosity then ansible_verbosity else '' end
  config.vm.provision :ansible do |ansible|
    ansible.playbook   = 'ansible/app.yml'
    ansible.extra_vars = app
    ansible.verbose    = verbosity_arg
  end

  # Plugins - Landrush
  if Vagrant.has_plugin?('landrush')
    config.landrush.enabled            = true
    config.landrush.tld                = config.vm.hostname
    config.landrush.guest_redirect_dns = false
  end

end
