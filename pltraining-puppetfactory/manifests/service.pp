class puppetfactory::service {
  package { 'puppetfactory':
    ensure   => present,
    provider => gem,
    before   => Service['puppetfactory'],
  }

  file { '/etc/systemd/system/puppetfactory.service':
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    mode    => '0664',
    source  => 'puppet:///modules/puppetfactory/puppetfactory.service',
    before  => Service['puppetfactory'],
  }

  service { 'puppetfactory':
    ensure    => running,
    enable    => true,
    subscribe => Package['puppetfactory'],
    require   => Class['docker'], # I don't like this coupling, but it's a reflection of reality
  }
}
