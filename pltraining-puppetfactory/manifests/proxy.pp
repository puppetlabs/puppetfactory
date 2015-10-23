# Use nginx to create a reverse proxy
class puppetfactory::proxy {
  assert_private('This class should not be called directly')

  package {'nginx':
    ensure => present,
  }
  file {'/etc/nginx/conf.d/default.conf':
    ensure  => file,
    source  => 'puppet:///modules/puppetfactory/default.conf',
    mode    => '0644',
    require => Package['nginx'],
  }
  file {'/etc/nginx/nginx.conf':
    ensure => file,
    source  => 'puppet:///modules/puppetfactory/nginx.conf',
    mode    => '0644',
    require => Package['nginx'],
  }
  service {'nginx':
    ensure  => running,
    require => [File['/etc/nginx/conf.d/default.conf'],File['/etc/nginx/nginx.conf']],
  }

  # This will allow the nginx proxy rules to work with selinux enabled
  if $puppetfactory::manage_selinux {
    selboolean { 'httpd_can_network_connect':
      value      => 'on',
      persistent => true,
    }
  }
}
