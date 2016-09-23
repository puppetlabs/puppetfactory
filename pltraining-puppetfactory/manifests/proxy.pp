# Use nginx to create a reverse proxy
class puppetfactory::proxy {
  assert_private('This class should not be called directly')

  File {
    owner => 'root',
    group => 'root',
    mode  => '0644',
  }

  package {'nginx':
    ensure => present,
  }
  file {'/etc/nginx/conf.d/default.conf':
    ensure  => file,
    source  => 'puppet:///modules/puppetfactory/default.conf',
    require => Package['nginx'],
  }
  file {'/etc/nginx/nginx.conf':
    ensure => file,
    source  => 'puppet:///modules/puppetfactory/nginx.conf',
    require => Package['nginx'],
  }
  service {'nginx':
    ensure    => running,
    enable    => true,
    subscribe => [File['/etc/nginx/conf.d/default.conf'],File['/etc/nginx/nginx.conf']],
  }

  file { '/etc/puppetfactory/html':
    ensure => directory,
  }
  file { '/etc/puppetfactory/html/404.html':
    ensure => file,
    source  => 'puppet:///modules/puppetfactory/html/404.html',
  }
  file { '/etc/puppetfactory/html/50x.html':
    ensure => file,
    source  => 'puppet:///modules/puppetfactory/html/50x.html',
  }

  # This will allow the nginx proxy rules to work with selinux enabled
  if $puppetfactory::manage_selinux {
    selboolean { 'httpd_can_network_connect':
      value      => 'on',
      persistent => true,
    }
  }
}
