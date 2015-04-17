class puppetfactory (
  $puppetcode = $puppetfactory::params::puppetcode,

  $ca_certificeate_path = $puppetfactory::params::ca_certificate_path,
  $certificate_path = $puppetfactory::params::certificate_path,
  $private_key_path = $puppetfactory::params::private_key_path,

  $classifier_url = $puppetfactory::params::classifier_url,

  $puppet = $puppetfactory::params::puppet,
  $rake = $puppetfactory::params::rake,

  $dash_path = $puppetfactory::params::dash_path,

  $docroot = $puppetfactory::params::docroot,
  $logfile = $puppetfactory::params::logfile,
  $cert_path = $puppetfactory::params::cert_path,
  $user = $puppetfactory::params::user,
  $password = $puppetfactory::params::password,
  $container_name = $puppetfactory::params::container_name,

  $confdir = $puppetfactory::params::confdir,
  $usersuffix = $puppetfactory::params::usersuffix,
  $puppetcode = $puppetfactory::params::puppetcode,

  $pe = $puppetfactory::params::pe,
) inherits puppetfactory::params {

  include puppetfactory::service
  include puppetfactory::shellinabox
  include puppetfactory::dockerenv
  include puppetfactory::proxy
  include epel

  file { '/etc/puppetlabs/puppet/environments/production/environment.conf':
    ensure  => file,
    content => "environment_timeout = 0\n",
    replace => false,
  }

  file { '/etc/puppetfactory.yaml':
    ensure  => present,
    content => template('puppetfactory/puppetfactory.yaml.erb'),
    before  => Service['puppetfactory'],
  }

  file_line { 'remove tty requirement':
    path  => '/etc/sudoers',
    line  => '#Defaults    requiretty',
    match => '^\s*Defaults    requiretty',
  }

  file_line { 'specifiy PUPPETCODE environment var':
    # NOTE: this will only take effect after a reboot
    path   => '/etc/environment',
    line   => "PUPPETCODE=${puppetcode}",
    match  => '^\s*PUPPETCODE.*',
    before => Package['puppetfactory'],
  }

  # sloppy, get this gone
  user { 'vagrant':
    ensure     => absent,
    managehome => true,
  }
  
  # Keep ssh sessions alive
  augeas{'sshd-clientalive':
    context => '/files/etc/ssh/sshd_config',
    changes => [
      'set ClientAliveInterval 300',
      'set ClientAliveCountMax 2'
    ],
  }
}
