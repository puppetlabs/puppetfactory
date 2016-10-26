class puppetfactory::dockerenv {
  assert_private('This class should not be called directly')
  
  include docker

  Class['docker'] {
    extra_parameters => '--default-ulimit nofile=1000000:1000000',
  }

  file {'/etc/security/limits.conf':
    ensure => file,
    source => 'puppet:///modules/puppetfactory/limits.conf',
    before => Class['docker'],
  }

  $puppetmaster = pick($puppetfactory::master, $servername)

  file { '/var/docker':
    ensure => directory,
  }

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

  # Ubuntu agent image
  file { '/var/docker/ubuntuagent/':
    ensure  => directory,
    recurse => true,
    source  => 'puppet:///modules/puppetfactory/ubuntu/',
    require => Class['docker'],
  }

  file { '/var/docker/ubuntuagent/Dockerfile':
    ensure  => present,
    content => template('puppetfactory/ubuntu.dockerfile.erb'),
    require => File['/var/docker/ubuntuagent/'],
    notify => Docker::Image['ubuntuagent'],
  }

  docker::image { 'ubuntuagent':
    docker_dir => '/var/docker/ubuntuagent/',
    require     => File['/var/docker/ubuntuagent/Dockerfile'],
  }

  # CentOS agent image
  file { '/var/docker/centosagent/':
    ensure  => directory,
    recurse => true,
    source  => 'puppet:///modules/puppetfactory/centos/',
    require => Class['docker'],
  }

  file { '/var/docker/centosagent/Dockerfile':
    ensure  => present,
    content => template('puppetfactory/centos.dockerfile.erb'),
    require => File['/var/docker/centosagent/'],
    notify => Docker::Image['centosagent'],
  }

  docker::image { 'centosagent':
    docker_dir => '/var/docker/centosagent/',
    require     => File['/var/docker/centosagent/Dockerfile'],
  }

}
