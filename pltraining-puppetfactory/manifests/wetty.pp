class puppetfactory::wetty {
  package { 'npm':
    ensure => present,
  }
  exec { 'npm -g install npm':
    path    => '/bin',
    onlyif  => 'npm -v | grep "1\.3\.6"',
    require => Package['npm'],
  }
  exec { 'npm -g install wetty':
    path    => '/bin',
    unless  => 'npm -g list wetty',
    require => Exec['npm -g install npm'],
  }

  file { '/etc/systemd/system/wetty.service':
    ensure => 'present',
    mode   => '0644',
    source => 'puppet:///modules/puppetfactory/wetty.conf',
  }
  service { 'wetty':
    ensure    => 'running',
    enable    => true,
    require   => Exec['npm -g install wetty'],
    subscribe => File['/etc/systemd/systemd/wetty.service'],
  }

  if $puppetfactory::manage_selinux {
    # Source code in weblogin.te
    file { '/usr/share/selinux/targeted/weblogin.pp':
      ensure => file,
      owner  => 'root',
      group  => 'root',
      mode   => '0644',
      source => 'puppet:///modules/puppetfactory/selinux/weblogin.pp',
    }

    selmodule { 'weblogin':
      ensure => present,
    }
  }
}
