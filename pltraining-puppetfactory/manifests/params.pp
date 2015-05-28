class puppetfactory::params {
  $ca_certificate_path = '/opt/puppet/share/puppet-dashboard/certs/ca_cert.pem'
  $certificate_path = '/opt/puppet/share/puppet-dashboard/certs/pe-internal-dashboard.cert.pem'
  $private_key_path = '/opt/puppet/share/puppet-dashboard/certs/pe-internal-dashboard.private_key.pem'

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

  $docker_group = 'docker'

  $pe = true
  $map_environments = false
}
