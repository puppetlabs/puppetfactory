require 'rspec-puppet'
# we can't use psh, because it declares things that conflict with serverspec

username = ENV['TARGET_HOST']
RSpec.configure do |c|
  c.environmentpath = "/etc/puppetlabs/code/environments"
  c.module_path     = "/etc/puppetlabs/code/environments/#{username}/modules"
  c.manifest_dir    = "/etc/puppetlabs/code/environments/#{username}/manifests"

  # Adds to the built in defaults from rspec-puppet
  c.default_facts = {
    :ipaddress                 => '127.0.0.1',
    :kernel                    => 'Linux',
    :operatingsystem           => 'CentOS',
    :operatingsystemmajrelease => '7',
    :osfamily                  => 'RedHat',
  }
end
