class puppetfactory::service {
  include pe_staging

  pe_staging::file { 'puppetfactory-0.1.0.gem':
    source  => 'puppet:///modules/puppetfactory/puppetfactory-0.1.0.gem'
  }

  package { 'puppetfactory':
    ensure   => present,
    provider => gem,
    source   => "${pe_staging::path}/puppetfactory/puppetfactory-0.1.0.gem",
    require  => Pe_staging::File['puppetfactory-0.1.0.gem'],
    before   => Service['puppetfactory'],
  }

  file { '/etc/init.d/puppetfactory':
    ensure => file,
    owner  => 'root',
    group  => 'root',
    mode   => 755,
    source => 'puppet:///modules/puppetfactory/puppetfactory.init',
    before => Service['puppetfactory'],
  }

  service { 'puppetfactory':
    ensure    => running,
    enable    => true,
    subscribe => Package['puppetfactory'],
  }
}
