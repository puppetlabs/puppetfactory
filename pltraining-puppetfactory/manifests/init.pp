class puppetfactory (
  $ca_certificate_path = $puppetfactory::params::ca_certificate_path,
  $certificate_path    = $puppetfactory::params::certificate_path,
  $private_key_path    = $puppetfactory::params::private_key_path,

  $puppetmaster        = $puppetfactory::params::puppetmaster,
  $classifier_url      = $puppetfactory::params::classifier_url,

  $puppet              = $puppetfactory::params::puppet,
  $rake                = $puppetfactory::params::rake,

  $docroot             = $puppetfactory::params::docroot,
  $logfile             = $puppetfactory::params::logfile,
  $cert_path           = $puppetfactory::params::cert_path,
  $user                = $puppetfactory::params::user,
  $password            = $puppetfactory::params::password,

  $confdir             = $puppetfactory::params::confdir,
  $codedir             = $puppetfactory::params::codedir,

  $usersuffix          = $puppetfactory::params::usersuffix,
  $puppetcode          = $puppetfactory::params::puppetcode,

  $container_name      = $puppetfactory::params::container_name,
  $docker_group        = $puppetfactory::params::docker_group,

  $manage_selinux      = $puppetfactory::params::manage_selinux,

  $pe                  = $puppetfactory::params::pe,
  $prefix              = $puppetfactory::params::prefix,
  $map_environments    = $puppetfactory::params::map_environments,
  $map_modulepath      = $puppetfactory::params::map_environments, # maintain backwards compatibility and simplicity
) inherits puppetfactory::params {

  include puppetfactory::proxy
  include puppetfactory::service
  include puppetfactory::shellinabox
  include puppetfactory::dockerenv
  include epel

  unless $pe {
    file { ["${codedir}/environments","${codedir}/environments/production"]:,
      ensure => directory,
    }
  }

  file { "${codedir}/environments/production/environment.conf":
    ensure  => file,
    content => "environment_timeout = 0\n",
    replace => false,
  }

  file { '/etc/puppetfactory.yaml':
    ensure  => present,
    content => template('puppetfactory/puppetfactory.yaml.erb'),
    notify  => Service['puppetfactory'],
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

  group { 'puppetfactory':
    ensure => present,
  }

  # Keep ssh sessions alive and allow puppetfactory users to log in with passwords
  class { "ssh::server":
    client_alive_interval          => 300,
    client_alive_count_max         => 2,
    password_authentication_groups => ['puppetfactory'],
  }

}
