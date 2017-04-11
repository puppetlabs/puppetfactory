class puppetfactory::dockerenv (
  $default_class = $puppetfactory::default_class
){
  assert_private('This class should not be called directly')
  class { 'docker':
    extra_parameters => '--default-ulimit nofile=1000000:1000000',
  }
  file {'/etc/security/limits.conf':
    ensure => file,
    source => 'puppet:///modules/puppetfactory/limits.conf',
    before => Class['docker'],
  }

  $puppetmaster = pick($puppetfactory::master, $servername)

  sysctl {'net.ipv4.ip_forward':
    ensure    => present,
    value     => '1',
    permanent => 'yes',
  }

  file { '/var/run/docker.sock':
    group   => $puppetfactory::docker_group,
    mode    => '0664',
    require => [Class['docker'],Group['docker']],
  }

  group { $puppetfactory::docker_group:
    ensure => present,
  }

  include puppetfactory::dockerimages
}

