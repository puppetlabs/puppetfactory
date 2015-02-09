class puppetfactory::service {
  include pe_staging

  pe_staging::file { 'puppetfactory-0.1.0.gem':
    source  => 'puppet:///modules/puppetfactory/puppetfactory-0.1.0.gem'
  }

  # Temporary pached version of puppetclassify remove when gem is published
  pe_staging::file { 'puppetclassify-0.1.1.gem':
    source  => 'puppet:///modules/puppetfactory/puppetclassify-0.1.1.gem'
  }
  package { 'puppetclassify':
    ensure   => present,
    provider => gem,
    source   => "${pe_staging::path}/puppetfactory/puppetclassify-0.1.1.gem",
    require  => Pe_staging::File['puppetclassify-0.1.1.gem'],
    before   => Package['puppetfactory'],
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
