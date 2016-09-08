class puppetfactory::dockerenv {
  assert_private('This class should not be called directly')
  include docker

  $puppetmaster = $puppetfactory::master

  file { '/var/docker':
    ensure => directory,
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
