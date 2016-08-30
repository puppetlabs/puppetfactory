class puppetfactory::dockerenv {
  assert_private('This class should not be called directly')

  $puppetmaster = $puppetfactory::puppetmaster

  include docker

  if $puppetfactory::pe {
    include pe_repo::platform::ubuntu_1404_amd64
  }

  if $puppetfactory::gitlab_enabled {
    include puppetfactory::gitlab
  }

  file { '/var/docker':
    ensure => directory,
  }

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


  file { '/var/run/docker.sock':
    group   => $puppetfactory::docker_group,
    mode    => '0664',
    require => [Class['docker'],Group['docker']],
  }

  group { $puppetfactory::docker_group:
    ensure => present,
  }

  # set up the shell expected by Puppetfactory
  file { '/usr/bin/dockershell':
    ensure => file,
    owner  => 'root',
    group  => 'root',
    mode   => '0755',
    source => 'puppet:///modules/puppetfactory/dockershell',
  }

  file_line { 'dockershell':
    ensure => present,
    path   => '/etc/shells',
    line   => '/usr/bin/dockershell',
  }
}
