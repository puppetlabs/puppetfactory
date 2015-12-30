require 'rspec-puppet'
# we can't use psh, because it declares things that conflict with serverspec

username = ENV['TARGET_HOST']
environmentpath = "/etc/puppetlabs/code/environments"

if File.directory? "#{environmentpath}/#{username}_production"
  environment = "#{username}_production"
else
  environment = username
end

RSpec.configure do |c|
  c.environmentpath = environmentpath
  c.module_path     = "#{environmentpath}/#{environment}/modules"
  c.manifest        = "#{environmentpath}/#{environment}/manifests"

  # Adds to the built in defaults from rspec-puppet
  c.default_facts = {
    :ipaddress                 => '127.0.0.1',
    :kernel                    => 'Linux',
    :operatingsystem           => 'CentOS',
    :operatingsystemmajrelease => '7',
    :osfamily                  => 'RedHat',
  }
end
