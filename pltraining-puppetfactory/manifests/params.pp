class puppetfactory::params {
  $ca_certificate_path = $settings::cacert
  $certificate_path    = $settings::hostcert
  $private_key_path    = $settings::hostprivkey

  $puppetmaster   = $::settings::certname
  $classifier_url = "http://${puppetmaster}:4433/classifier-api"

  $puppet = '/opt/puppetlabs/puppet/bin/puppet'
  $rake   = '/opt/puppetlabs/puppet/bin/rake'

  $docroot   = '/opt/puppetfactory'
  $logfile   = '/var/log/puppetfactory'
  $cert_path = 'certs'
  $user      = 'admin'
  $password  = 'admin'

  $confdir = '/etc/puppetlabs/puppet'
  $codedir = '/etc/puppetlabs/code'

  $usersuffix = 'puppetlabs.vm'
  $puppetcode = '/root/puppetcode'

  $container_name = 'centosagent'
  $docker_group   = 'docker'

  $dashboard = false

  # support for old facter versions
  $manage_selinux = $::os['selinux'] ? {
    undef   => $::selinux,
    default => $::os['selinux']['enabled'],
  }

  $pe               = true
  $prefix           = false
  $map_environments = false
}
