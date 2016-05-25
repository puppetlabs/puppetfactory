class puppetfactory::profile::pi (
  $session_id = $puppetfactory::params::session_id,
) inherits puppetfactory::params {

  File {
    owner => 'root',
    group => 'root',
    mode  => '0644',
  }

  rbac_user { 'deployer':
    ensure       => 'present',
    name         => 'deployer',
    dipslay_name => 'Code Manager deployment user',
    email        => 'deployer@master.puppetlabs.vm',
    password     => 'puppetlabs',
    roles        => [ 'Administrators' ],
  }

  ensure_packages(['gcc','zlib', 'zlib-devel'], {
    before => Package['puppetfactory']
  })

  package { ['serverspec', 'puppetlabs_spec_helper']:
    ensure   => present,
    provider => gem,
    require  => Package['puppet'],
  }

  # lol, this is great.
  package { 'puppet':
    ensure          => present,
    provider        => gem,
    install_options => { '--bindir' => '/tmp' },
  }

  class { 'puppetfactory::profile::showoff':
    password => $session_id,
  }

  class { 'puppetfactory':
    prefix           => false,
    map_environments => false,
    map_modulepath   => false,
    dashboard        => "${showoff::root}/courseware/_files/tests",
    session_id       => $session_id,
    gitlab_enabled   => false,
  }

  class { 'puppetfactory::facts':
    coursename => 'pi',
  }

  # Because PE writes a default, we have to do tricks to see if we've already managed this.
  # We don't want to stomp on instructors doing demonstrations.
  unless defined('$puppetlabs_class') {
    file { '/etc/puppetlabs/code/hiera.yaml':
      ensure  => file,
      source => 'puppet:///modules/puppetfactory/pi/hiera.yaml',
    }
  }
}
