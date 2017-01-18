class puppetfactory (
  Boolean $manage_gitlab  = $puppetfactory::params::manage_gitlab,
  Boolean $manage_selinux = $puppetfactory::params::manage_selinux,
  Boolean $autosign       = $puppetfactory::params::autosign,
  String  $docker_group   = $puppetfactory::params::docker_group,   # why are some of these items configurable?
  String  $stagedir       = $puppetfactory::params::stagedir,       # unfortunately $stagedir is not in $settings...
  String  $default_class  = $puppetfactory::params::default_class,  # Puppet class to apply to student nodes

  String  $confdir        = $settings::confdir,
  String  $codedir        = $settings::codedir,
  String  $environments   = $settings::environmentpath,

  Optional[Array]   $plugins            = undef,
  Optional[String]  $puppet             = undef,
  Optional[String]  $root               = undef,
  Optional[String]  $logfile            = undef,
  Optional[String]  $templatedir        = undef,
  Optional[Integer] $port               = undef,
  Optional[String]  $bind               = undef,
  Optional[String]  $user               = undef,
  Optional[String]  $password           = undef,
  Optional[String]  $session            = undef,
  Optional[String]  $master             = undef,
  Optional[String]  $usersuffix         = undef,
  Optional[Array]   $usergroups         = undef,
  Optional[String]  $puppetcode         = undef,
  Optional[String]  $gitserver          = undef,
  Optional[String]  $gituser            = undef,
  Optional[String]  $githubtoken        = undef,
  Optional[String]  $controlrepo        = undef,
  Optional[Boolean] $prefix             = undef,
  Optional[String]  $classifier         = undef,
  Optional[Hash]    $auth_info          = undef,
  Optional[String]  $dashboard_path     = undef,
  Optional[Integer] $dashboard_interval = undef,
  Optional[String]  $container          = undef,
  Optional[String]  $docker_ip          = undef,
  Optional[Boolean] $privileged         = undef,
  Optional[String]  $hooks_path         = undef,

  Optional[Enum['single', 'peruser']] $repomodel              = undef,
  Optional[Enum['readwrite', 'readonly', 'none']] $modulepath = undef,

) inherits puppetfactory::params {
  # TODO: port these to use puppet-tea and puppet-ip
  if $bind           { validate_ip_address($bind)              }
  if $docker_ip      { validate_ip_address($docker_ip)         }

  if $puppet         { validate_absolute_path($puppet)         }
  if $confdir        { validate_absolute_path($confdir)        }
  if $codedir        { validate_absolute_path($codedir)        }
  if $environments   { validate_absolute_path($environments)   }
  if $root           { validate_absolute_path($root)           }
  if $logfile        { validate_absolute_path($logfile)        }
  if $templatedir    { validate_absolute_path($templatedir)    }
  if $puppetcode     { validate_absolute_path($puppetcode)     }
  if $dashboard_path { validate_absolute_path($dashboard_path) }
  if $hooks_path     { validate_absolute_path($hooks_path)     }

  include puppetfactory::proxy
  include puppetfactory::service
  include puppetfactory::dockerenv
  include epel

  if $manage_gitlab {
    include puppetfactory::gitlab
    $real_gitserver = pick($gitserver, 'http://localhost:8888')
  }
  else {
    $real_gitserver = pick($gitserver, 'https://github.com')
  }

  class { 'abalone':
    port => '4200',
  }

  # TODO: should this be gated on the container name or some such? Do we care?
  # if we're on a PE master, set up so we can serve ubuntu nodes
  if $::pe_server_version {
    include pe_repo::platform::ubuntu_1404_amd64
  }

  file_line { 'puppetfactory autosign':
    ensure => $autosign ? {
        true  => present,
        false => absent,
      },
    path   => "${confdir}/autosign.conf",
    line   => '*',
  }

  file { '/etc/puppetfactory/config.yaml':
    ensure  => present,
    content => template('puppetfactory/config.yaml.erb'),
    notify  => Service['puppetfactory'],
  }

  file_line { 'Puppetfactory login shell':
    ensure => present,
    path   => '/etc/shells',
    line   => '/usr/local/bin/pfsh',
  }

  $hooks = ['/etc/puppetfactory/',
            '/etc/puppetfactory/hooks/',
            '/etc/puppetfactory/hooks/create',
            '/etc/puppetfactory/hooks/delete',
           ]

  file { $hooks:
    ensure => directory,
  }

  group { 'puppetfactory':
    ensure => present,
  }

  # TODO: should the rest of this be in some profile class?
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

  file { '/etc/issue.net':
    ensure => file,
    source => 'puppet:///modules/puppetfactory/issue.net',
  }

  # Keep ssh sessions alive and allow puppetfactory users to log in with passwords
  # disable root login on EC2 but enable everywhere else
  $allow_root = $ec2_metadata ? {
    undef   => 'yes',
    default => 'no',
  }
  class { "ssh::server":
    client_alive_interval          => 300,
    client_alive_count_max         => 2,
    password_authentication        => $allow_root,
    permit_root_login              => $allow_root,
    password_authentication_groups => ['puppetfactory'],
    host_keys                      => ['/etc/ssh/ssh_host_rsa_key','/etc/ssh/ssh_host_ecdsa_key', '/etc/ssh/ssh_host_ed25519_key']
  }

}
