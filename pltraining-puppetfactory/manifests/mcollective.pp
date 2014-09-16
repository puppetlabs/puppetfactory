class puppetfactory::mcollective {
  File {
    owner => 'root',
    group => 'root',
    mode  => '0644',
  }

  # mcollective bits
  file { '/usr/local/bin/refresh-user-mcollective-data':
    ensure => file,
    mode   => '0755',
    source => 'puppet:///modules/puppetfactory/refresh-user-mcollective-data',
  }

  cron { 'refresh-user-mcollective-data':
    ensure  => present,
    command => '/usr/local/bin/refresh-user-mcollective-data',
    minute  => ['1', '16', '31', '46'],
  }

  file { '/etc/init.d/user-mcollective':
    ensure => file,
    mode   => '0755',
    source => 'puppet:///modules/puppetfactory/user-mcollective.init',
  }

  service { 'user-mcollective':
    ensure    => running,
    enable    => true,
    subscribe => File['/etc/init.d/user-mcollective'],
  }

}
