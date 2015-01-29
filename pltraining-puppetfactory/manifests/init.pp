class puppetfactory {
  include puppetfactory::service
  include puppetfactory::doppelganger
  include puppetfactory::shellinabox
  include puppetfactory::mcollective
  include puppetfactory::evil          # default providers should only be used by root
  include docker

  Ini_setting {
    path    => '/etc/puppetlabs/puppet/puppet.conf',
    section => 'main',
    notify  => Service['pe-httpd'],
  }
  File {
    notify  => Service['pe-httpd'],
  }

  file { ['/etc/puppetlabs/puppet/environments','/etc/puppetlabs/puppet/environments/production']:
    ensure => directory,
  }

  file { '/etc/puppetlabs/puppet/environments/production/modules':
    ensure => link,
    target => '/etc/puppetlabs/puppet/modules',
  }

  file { '/etc/puppetlabs/puppet/environments/production/manifests':
    ensure => link,
    target => '/etc/puppetlabs/puppet/manifests',
  }

  file { '/etc/puppetlabs/puppet/environments/production/environment.conf':
    ensure  => file,
    content => "environment_timeout = 0\n",
    replace => false,
  }

  ini_setting { 'environmentpath':
    ensure  => present,
    setting => 'environmentpath',
    value   => '/etc/puppetlabs/puppet/environments',
  }

  ini_setting { 'base modulepath':
    ensure  => present,
    setting => 'basemodulepath',
    value   => '/etc/puppetlabs/puppet/modules:/opt/puppet/share/puppet/modules',
  }

  ini_setting { 'default manifest path':
    ensure  => present,
    setting => 'default_manifest',
    value   => '/etc/puppetlabs/puppet/manifests/site.pp',
  }

  service {'pe-httpd':
    ensure  => running,
    enable  => true,
  }

  # sloppy, get this gone
  user { 'vagrant':
    ensure     => absent,
    managehome => true,
  }

  # ensure the packages used by userprefs are available so that the simulated
  # installation labs appear to work properly.
  package { ['zsh', 'emacs', 'nano' ]:
    ensure => present,
  }
}
