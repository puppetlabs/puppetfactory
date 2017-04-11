class puppetfactory::dockerimages {

  file { '/var/docker':
    ensure => directory,
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

  # Mount the mirror directory because docker doesn't follow symlinks
  # mount --bind /var/yum/mirror mirror
  file {'/var/docker/centosagent/mirror':
    ensure => directory,
    before => Mount['/var/docker/centosagent/mirror'],
  }
  mount {'/var/docker/centosagent/mirror':
    ensure  => mounted,
    atboot  => true,
    device  => '/var/yum/mirror',
    fstype  => 'xfs',
    options => 'bind',
    before  => Docker::Image['centosagent']
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

