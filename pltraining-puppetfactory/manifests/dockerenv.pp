class puppetfactory::dockerenv {
  class { 'docker':
    require => Yumrepo['base'],
  }

  file { '/etc/docker/centosagent/':
    ensure  => directory,
    recurse => true,
    source  => 'puppet:///modules/puppetfactory/centos/',
    require => Class['docker'],
  }

  docker::image { 'centosagent':
    docker_dir => '/etc/docker/centosagent/',
    require     => File['/etc/docker/centosagent/'],
  }
}
