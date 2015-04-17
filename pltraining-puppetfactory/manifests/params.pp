class puppetfactory::params {
  $classifier_url = "http://${::fqdn}:4433/classifier-api"

  $puppet = '/opt/puppet/bin/puppet'
  $rake = '/opt/puppet/bin/rake'

  $dash_path = '/opt/puppet/share/puppet-dashboard'

  $docroot = '/opt/puppetfactory'
  $logfile = '/var/log/puppetfactory'
  $cert_path = 'certs'
  $user = 'admin'
  $password = 'admin'
  $container_name = 'centosagent'

  $confdir = '/etc/puppetlabs/puppet/'
  $usersuffix = 'puppetlabs.vm'
  $puppetcode = '/root/puppetcode'

  $pe = false
}
