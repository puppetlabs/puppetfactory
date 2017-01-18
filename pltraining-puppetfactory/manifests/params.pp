class puppetfactory::params {
  # support for old facter versions
  $manage_selinux = $::os['selinux'] ? {
    undef   => $::selinux,
    default => $::os['selinux']['enabled'],
  }

  # for whatever reason, CodeManager/FileSync settings aren't available in $settings
  $stagedir = '/etc/puppetlabs/code-staging'

  $autosign      = false
  $manage_gitlab = false
  $docker_group  = 'docker'
  # Apply course_selector to all student nodes on first boot by default
  $default_class = 'course_selector'

  $plugins = [ "Certificates", "Classification", "Docker", "Logs", "Dashboard", "CodeManager", "ShellUser" ]
}
