# Open Source Puppet Master
class { 'puppetfactory':
  ca_certificate_path => '/opt/puppet/share/puppet-dashboard/certs/ca_cert.pem',
  certificate_path    => '/opt/puppet/share/puppet-dashboard/certs/pe-internal-dashboard.cert.pem',
  private_key_path    => '/opt/puppet/share/puppet-dashboard/certs/pe-internal-dashboard.private_key.pem',

  classifier_url      => "http://${::fqdn}:4433/classifier-api",

  puppet => '/usr/bin/puppet',
  rake   => '/usr/bin/rake',

  docroot        => '/opt/puppetfactory',
  logfile        => '/var/log/puppetfactory',
  cert_path      => 'certs',
  user           => 'admin',
  password       => 'admin',
  container_name => 'centosagent',

  confdir    => '/etc/puppet/',
  usersuffix => 'puppetlabs.vm',
  puppetcode => '/root/puppetcode',

  pe => false,
}
