class puppetfactory::shellinabox {
  assert_private('This class should not be called directly')

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

  if $puppetfactory::manage_selinux {
    # Source code in shellinabox.te
    file { '/usr/share/selinux/targeted/shellinabox.pp':
      ensure => file,
      owner  => 'root',
      group  => 'root',
      mode   => '0644',
      source => 'puppet:///modules/puppetfactory/shellinabox.pp',
    }

    selmodule { 'shellinabox':
      ensure => present,
    }
  }
}
