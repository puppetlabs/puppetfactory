class puppetfactory::profile::puppetize (
  $session_id = $puppetfactory::params::session_id,
) inherits puppetfactory::params {

  if $::fqdn == 'master.puppetlabs.vm' {
    # Classroom Master
    File {
      owner => 'root',
      group => 'root',
      mode  => '0644',
    }

    # <Workaround for PE-15399>
    pe_hocon_setting { 'file-sync.client.stream-file-threshold':
      path    => '/etc/puppetlabs/puppetserver/conf.d/file-sync.conf',
      setting => 'file-sync.client.stream-file-threshold',
      value   => 512,
    }
    # </Workaround> 

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
        map_environments => true,
        map_modulepath   => false,
        dashboard        => "${showoff::root}/courseware/_files/tests",
        session_id       => $session_id,
        gitlab_enabled   => false,
      }

      class { 'puppetfactory::facts':
        coursename => 'puppetizing',
      }

      # Because PE writes a default, we have to do tricks to see if we've already managed this.
      # We don't want to stomp on instructors doing demonstrations.
      unless defined('$puppetlabs_class') {
        file { '/etc/puppetlabs/code/hiera.yaml':
          ensure  => file,
          source => 'puppet:///modules/puppetfactory/puppetizing/hiera.yaml',
        }
      }

    } else {
      if $::osfamily == 'windows' {
        # Windows Agents
        include chocolatey
      } else {
        # Linux Agents
      }
      
    }
}
