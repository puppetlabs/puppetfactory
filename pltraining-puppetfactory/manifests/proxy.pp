# Use nginx to create a reverse proxy
class puppetfactory::proxy {
  package {'nginx':
    ensure => present,
  }
  file {'/etc/nginx/default.conf':
    ensure  => file,
    source  => 'puppet:///modules/puppetfactory/default.conf',
    require => Package['nginx'],
  }
  service {'nginx':
    ensure  => running,
    require => File['/etc/nginx/default.conf'],
  }
}
