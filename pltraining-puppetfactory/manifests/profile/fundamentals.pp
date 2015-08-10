class puppetfactory::profile::fundamentals {

  File {
    owner => 'root',
    group => 'root',
    mode  => '0644',
  }

  file { '/etc/puppetlabs/r10k/r10k.yaml':
    ensure  => file,
    replace => false,
    source  => 'puppet:///modules/puppetfactory/fundamentals/r10k.yaml',
  }

  $hooks = ['/etc/puppetfactory',
            '/etc/puppetfactory/hooks',
            '/etc/puppetfactory/hooks/create',
            '/etc/puppetfactory/hooks/delete',
          ]

  file { $hooks:
    ensure => directory,
  }

  file { '/etc/puppetfactory/hooks/create/r10k_create_user.rb':
    ensure => file,
    mode   => '0755',
    source => 'puppet:///modules/puppetfactory/fundamentals/r10k_env.rb',
  }

  # this looks wonky, but the script uses its name to determine mode of operation
  file { '/etc/puppetfactory/hooks/delete/r10k_delete_user.rb':
    ensure => link,
    target => '/etc/puppetfactory/hooks/create/r10k_create_user.rb',
  }

  class {'r10k::webhook::config':
    enable_ssl        => false,
    protected         => false,
    use_mcollective   => false,
    prefix            => ':user',
    repository_events => ['release'],
  }

  class {'r10k::webhook':
    user    => 'root',
    require => Class['r10k::webhook::config'],
  }
}
