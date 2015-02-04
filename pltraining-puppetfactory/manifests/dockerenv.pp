class puppetfactory::dockerenv {
  include docker

  file { '/etc/docker/puppetbase/':
    ensure  => directory,
    require => Class['docker'],
  }
  file { '/etc/docker/puppetbase/Dockerfile':
    source  => 'puppet:///modules/puppetfactory/puppetbase/Dockerfile',
    require => File['/etc/docker/puppetbase/'],
  }

  docker::image { 'puppetbase':
    docker_file => '/etc/docker/puppetbase/Dockerfile',
    require     => File['/etc/docker/puppetbase/Dockerfile'],
  }
  yumrepo { 'base':
    enabled => 1,
    before  => Class['docker'],
  }
}
