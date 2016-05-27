class puppetfactory::service {
  class{ 'staging':
    path => '/var/staging/'
  }

  staging::file { 'puppetfactory-0.3.8.gem':
    source  => 'puppet:///modules/puppetfactory/puppetfactory-0.3.8.gem'
  }

  package { 'puppetclassify':
    ensure   => present,
    provider => gem,
    before   => Package['puppetfactory'],
  }

  package { 'puppetfactory':
    ensure   => present,
    provider => gem,
    source   => "${staging::path}/puppetfactory/puppetfactory-0.3.8.gem",
    require  => Staging::File['puppetfactory-0.3.8.gem'],
    before   => Service['puppetfactory'],
  }

  file { '/etc/systemd/system/puppetfactory.service':
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    mode    => '0664',
    content => template('puppetfactory/puppetfactory.init.erb'),
    before  => Service['puppetfactory'],
  }

  service { 'puppetfactory':
    ensure    => running,
    enable    => true,
    subscribe => Package['puppetfactory'],
    require   => Class['docker'], # I don't like this coupling, but it's a reflection of reality
  }
}
