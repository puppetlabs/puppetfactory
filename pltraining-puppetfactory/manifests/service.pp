class puppetfactory::service {
  class{ 'staging':
    path => '/var/staging/'
  }

  staging::file { 'puppetfactory-0.1.4.gem':
    source  => 'puppet:///modules/puppetfactory/puppetfactory-0.1.4.gem'
  }

  # Temporary pached version of puppetclassify remove when gem is published
  staging::file { 'puppetclassify-0.1.1.gem':
    source  => 'puppet:///modules/puppetfactory/puppetclassify-0.1.1.gem'
  }
  package { 'puppetclassify':
    ensure   => present,
    provider => gem,
    source   => "${staging::path}/puppetfactory/puppetclassify-0.1.1.gem",
    require  => Staging::File['puppetclassify-0.1.1.gem'],
    before   => Package['puppetfactory'],
  }

  package { 'puppetfactory':
    ensure   => present,
    provider => gem,
    source   => "${staging::path}/puppetfactory/puppetfactory-0.1.4.gem",
    require  => Staging::File['puppetfactory-0.1.4.gem'],
    before   => Service['puppetfactory'],
  }

  file { '/etc/init.d/puppetfactory':
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    mode    => 755,
    content => template('puppetfactory/puppetfactory.init.erb'),
    before  => Service['puppetfactory'],
  }

  service { 'puppetfactory':
    ensure    => running,
    enable    => true,
    subscribe => Package['puppetfactory'],
  }
}
