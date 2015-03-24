class puppetfactory (
  $puppetcode = $puppetfactory::params::puppetcode
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
}
