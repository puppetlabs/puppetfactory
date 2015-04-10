class puppetfactory::shellinabox {
  package { 'shellinabox':
    ensure  => present,
    require => Class['epel'],
  }

  file { '/etc/sysconfig/shellinaboxd':
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    source  => 'puppet:///modules/puppetfactory/shellinabox.conf',
    require => Package['shellinabox'],
  }

  service { 'shellinaboxd':
    ensure    => running,
    enable    => true,
    subscribe => File['/etc/sysconfig/shellinaboxd'],
  }
}
