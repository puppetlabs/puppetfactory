class puppetfactory {
  include puppetfactory::service
  include puppetfactory::shellinabox
  include docker
  include epel

  file { '/etc/Dockerfile':
    source => 'puppet:///modules/puppetfactory/Dockerfile'
  }

  docker::image { 'puppetfactory':
    docker_file => '/etc/Dockerfile',
    require     => File['/etc/Dockerfile'],
  }

  file { '/etc/puppetlabs/puppet/environments/production/environment.conf':
    ensure  => file,
    content => "environment_timeout = 0\n",
    replace => false,
  }

  file_line { 'remove tty requirement':
    path  => '/etc/sudoers',
    line  => '#Defaults    requiretty',
    match => '^\s*Defaults    requiretty',
  }

  # sloppy, get this gone
  user { 'vagrant':
    ensure     => absent,
    managehome => true,
  }

  # ensure the packages used by userprefs are available so that the simulated
  # installation labs appear to work properly.
  package { ['zsh', 'emacs', 'nano', 'vim-enhanced', 'rubygems', 'tree', 'git' ]:
    ensure  => present,
    require => Class['epel'],
    before  => Class['puppetfactory::service'],
  }
}
