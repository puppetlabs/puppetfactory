class puppetfactory::doppelganger {
  File {
    owner => 'root',
    group => 'root',
    mode  => '0644',
  }

  pe_staging::file { 'doppelganger-0.0.1.gem':
    source  => 'puppet:///modules/puppetfactory/doppelganger-0.0.1.gem'
  }

  package { 'doppelganger':
    ensure   => present,
    provider => pe_puppetserver_gem,
    source   => "${pe_staging::path}/puppetfactory/doppelganger-0.0.1.gem",
    require  => Pe_staging::File['doppelganger-0.0.1.gem'],
  }

  exec { 'doppelganger':
    command => "/opt/puppet/bin/gem install ${pe_staging::path}/puppetfactory/doppelganger-0.0.1.gem",
    creates => '/opt/puppet/bin/pl-package',
    require => Pe_staging::File['doppelganger-0.0.1.gem'],
  }

  file { '/usr/local/bin/pl-package':
    ensure => link,
    target => '/opt/puppet/bin/pl-package',
  }

  file { '/usr/local/bin/pl-service':
    ensure => link,
    target => '/opt/puppet/bin/pl-service',
  }

  file { '/usr/local/bin/pl-user':
    ensure => link,
    target => '/opt/puppet/bin/pl-user',
  }
}