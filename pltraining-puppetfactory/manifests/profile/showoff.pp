class puppetfactory::profile::showoff (
  String $preso,
  Boolean $virtual = true,
) {
  $courses = [
    'appropriate_module_design',
    'aws',
    'fundamentals',
    'infrastructure_design',
    'intro',
    'managing_puppet_code',
    'practical_hiera_usage',
    'puppet_4_parser',
    'troubleshooting',
    'windows_essentials',
    'writing_your_first_module'
  ]
  unless $preso in $courses { fail("${preso} is not recognized as a virtual course we deliver.") }

  $repository = $virtual ? {
    true  => 'git@github.com:puppetlabs/courseware-virtual.git',
    false => 'git@github.com:puppetlabs/courseware.git',
  }

  $github_host_key = "AAAAB3NzaC1yc2EAAAABIwAAAQEAq2A7hRGmdnm9tUDbO9IDSwBK6TbQa+PXYPCPy6rbTrTtw7PHkccKrpp0yVhp5HdEIcKr6pLlVDBfOLX9QUsyCOV0wzfjIJNlGEYsdlLJizHhbn2mUjvSAHQqZETYP81eFzLQNnPHt4EVVUh7VfDESU84KezmD5QlWpXLmvU31/yMf+Se8xhHTvKSCZIFImWwoG6mbUoWf9nzpIoaSjB+weqqUUmpaaasXVal72J+UX2B+2RPW3RcT0eOzQgqlJL3RKrTJvdsjE3JEAvGq3lGHSZXy28G3skua2SmVi/w4yCE6gbODqnTWlg7+wC604ydGXA8VJiS5ap43JXiUFFAaQ=="

  include showoff

  file { "/home/${showoff::user}/.ssh/id_rsa":
    ensure  => file,
    owner   => $showoff::user,
    group   => $showoff::group,
    mode    => '0600',
    source  => '/root/.ssh/github_rsa',
    require => Class['showoff'],
  }

  sshkey { 'github key':
    name         => 'github.com',
    host_aliases => '192.30.252.129',
    type         => 'ssh-rsa',
    target       => "/home/${showoff::user}/.ssh/known_hosts",
    key          => $github_host_key,
  }

  vcsrepo { "${showoff::root}/courseware":
    ensure   => present,
    provider => git,
    user     => $showoff::user,
    source   => $repository,
    require  => Sshkey['github key'],
  }

  showoff::presentation { $preso:
    path     => "${showoff::root}/courseware/${preso}",
    require  => Vcsrepo["${showoff::root}/courseware"],
  }

}
