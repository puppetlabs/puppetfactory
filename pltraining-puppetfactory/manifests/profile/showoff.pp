class puppetfactory::profile::showoff (
  Optional[String] $password,
) {
  require showoff
  require puppetfactory::profile::pdf_stack

  $courseware_source = '/root/courseware'

  # We use this resource so that any time an instructor uploads new content,
  # the PDF files will be rebuilt via the dependent exec statement
  # This source path will be created via a courseware rake task.
  file { "${showoff::root}/courseware":
    ensure   => directory,
    owner    => $showoff::user,
    mode     => '0644',
    source   => $courseware_source,
    notify   => Exec['build_pdfs'],
  }

  exec { 'build_pdfs':
    command     => "rake watermark target=_files/share password=${password}",
    cwd         => "${showoff::root}/courseware/",
    path        => '/bin:/usr/bin:/usr/local/bin',
    environment => ['HOME=/root'],
    refreshonly => true,
  }

  showoff::presentation { $preso:
    path     => "${showoff::root}/courseware/",
    require  => Vcsrepo["${showoff::root}/courseware"],
  }

}
