class puppetfactory::params {
  $ca_certificate_path = $settings::cacert
  $certificate_path    = $settings::hostcert
  $private_key_path    = $settings::hostprivkey

  $classifier_url = "http://${::fqdn}:4433/classifier-api"

  $puppet = '/opt/puppetlabs/puppet/bin/puppet'
  $rake = '/opt/puppetlabs/puppet/bin/rake'

  $dash_path = '/opt/puppet/share/puppet-dashboard'

  $docroot = '/opt/puppetfactory'
  $logfile = '/var/log/puppetfactory'
  $cert_path = 'certs'
  $user = 'admin'
  $password = 'admin'
  $container_name = 'centosagent'

  $confdir = '/etc/puppetlabs/puppet/'
  $codedir = '/etc/puppetlabs/code/'
  $usersuffix = 'puppetlabs.vm'
  $puppetcode = '/root/puppetcode'

  $docker_group = 'docker'

  $pe = true
  $map_environments = false
}
