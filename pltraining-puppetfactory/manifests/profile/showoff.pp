class puppetfactory::profile::showoff (
  Optional[String] $password,
  String $courseware_source = '/home/centos/courseware',
) {
  include stunnel
  require showoff
  require puppetfactory::profile::pdf_stack

  # We use this resource so that any time an instructor uploads new content,
  # the PDF files will be rebuilt via the dependent exec statement
  # This source path will be created via a courseware rake task.
  file { "${showoff::root}/courseware":
    ensure  => directory,
    owner   => $showoff::user,
    group   => 'root',
    mode    => '0644',
    seluser => undef,
    recurse => true,
    source  => $courseware_source,
    notify  => Exec['build_pdfs'],
  }

  exec { 'build_pdfs':
    command     => "rake watermark target=_files/share password=${password}",
    cwd         => "${showoff::root}/courseware/",
    path        => '/bin:/usr/bin:/usr/local/bin',
    user        => $showoff::user,
    group       => 'root',
    environment => ["HOME=${showoff::root}"],
    refreshonly => true,
  }

  showoff::presentation { 'courseware':
    path      => "${showoff::root}/courseware/",
    subscribe => File["${showoff::root}/courseware"],
  }

  file { '/etc/stunnel/showoff.pem':
    ensure => 'file',
    owner  => 'root',
    group  => 'root',
    mode   => '0600',
    source => 'puppet:///modules/puppetfactory/showoff.pem',
    before => Stunnel::Tun['showoff-ssl'],
  }

  stunnel::tun { 'showoff-ssl':
    accept  => '9091',
    connect => 'localhost:9090',
    options => 'NO_SSLv2',
    cert    => '/etc/stunnel/showoff.pem',
    client  => false,
  }

  if $puppetfactory::manage_selinux {
    # Source code in stunnel-showoff.te
    file { '/usr/share/selinux/targeted/stunnel-showoff.pp':
      ensure => file,
      owner  => 'root',
      group  => 'root',
      mode   => '0644',
      source => 'puppet:///modules/puppetfactory/selinux/stunnel-showoff.pp',
    }

    selmodule { 'stunnel-showoff':
      ensure => present,
    }
  }

}
