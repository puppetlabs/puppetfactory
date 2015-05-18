class puppetfactory::dockerenv {
  include docker

  file { '/etc/docker/centosagent/':
    ensure  => directory,
    recurse => true,
    source  => 'puppet:///modules/puppetfactory/centos/',
    require => Class['docker'],
  }

  file { '/etc/docker/centosagent/Dockerfile':
    ensure  => present,
    content => template('puppetfactory/Dockerfile.erb'),
    require => File['/etc/docker/centosagent/'],
    notify => Docker::Image['centosagent'],
  }

  docker::image { 'centosagent':
    docker_dir => '/etc/docker/centosagent/',
    require     => File['/etc/docker/centosagent/Dockerfile'],
  }

  file { '/var/run/docker.sock':
    group   => 'docker',
    require => [Class['docker'],Group['docker']],
  }

  group { 'docker':
    ensure => present,
  }
}
