class puppetfactory::params {
  # support for old facter versions
  $manage_selinux = $::os['selinux'] ? {
    undef   => $::selinux,
    default => $::os['selinux']['enabled'],
  }

  $autosign      = false
  $manage_gitlab = false
  $docker_group  = 'docker'

  $plugins = [ "Certificates", "Classification", "Docker", "Logs", "Dashboard", "CodeManager", "ShellUser" ]
}
