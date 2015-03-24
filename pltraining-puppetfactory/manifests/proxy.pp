# Use nginx to create a reverse proxy
class puppetfactory::proxy {
  package {'nginx':
    ensure => present,
  }
  file {'/etc/nginx/conf.d/default.conf':
    ensure  => file,
    source  => 'puppet:///modules/puppetfactory/default.conf',
    mode    => '0644',
    require => Package['nginx'],
  }
  service {'nginx':
    ensure  => running,
    require => File['/etc/nginx/conf.d/default.conf'],
  }
}
