class puppetfactory::dockerenv {
  assert_private('This class should not be called directly')

  $puppetmaster = $puppetfactory::puppetmaster

  include docker

  if $puppetfactory::pe {
    include pe_repo::platform::ubuntu_1404_amd64
  }

  file { '/etc/docker/ubuntuagent/':
    ensure  => directory,
    recurse => true,
    source  => 'puppet:///modules/puppetfactory/ubuntu/',
    require => Class['docker'],
  }

  file { '/etc/docker/ubuntuagent/Dockerfile':
    ensure  => present,
    content => template('puppetfactory/ubuntu.dockerfile.erb'),
    require => File['/etc/docker/ubuntuagent/'],
    notify => Docker::Image['ubuntuagent'],
  }

  docker::image { 'ubuntuagent':
    docker_dir => '/etc/docker/ubuntuagent/',
    require     => File['/etc/docker/ubuntuagent/Dockerfile'],
  }

  file { '/etc/docker/centosagent/':
    ensure  => directory,
    recurse => true,
    source  => 'puppet:///modules/puppetfactory/centos/',
    require => Class['docker'],
  }

  file { '/etc/docker/centosagent/Dockerfile':
    ensure  => present,
    content => template('puppetfactory/centos.dockerfile.erb'),
    require => File['/etc/docker/centosagent/'],
    notify => Docker::Image['centosagent'],
  }

  docker::image { 'centosagent':
    docker_dir => '/etc/docker/centosagent/',
    require     => File['/etc/docker/centosagent/Dockerfile'],
  }


  file { '/var/run/docker.sock':
    group   => $puppetfactory::docker_group,
    mode    => '0664',
    require => [Class['docker'],Group['docker']],
  }

  group { $puppetfactory::docker_group:
    ensure => present,
  }
}
