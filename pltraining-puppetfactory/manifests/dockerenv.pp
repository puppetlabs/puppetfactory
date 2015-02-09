class puppetfactory::dockerenv {
  include docker

  file { '/etc/docker/centosagent/':
    ensure  => directory,
    require => Class['docker'],
  }
  file { '/etc/docker/centosagent/Dockerfile':
    source  => 'puppet:///modules/puppetfactory/centos/Dockerfile',
    require => File['/etc/docker/centosagent/'],
  }

  docker::image { 'centosagent':
    docker_file => '/etc/docker/centosagent/Dockerfile',
    require     => File['/etc/docker/centosagent/Dockerfile'],
  }
  yumrepo { 'base':
    enabled => 1,
    before  => Class['docker'],
  }
}
