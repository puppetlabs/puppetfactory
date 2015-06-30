class puppetfactory::profile::code_management {
  # Classroom for the codemanagement course
  class { 'puppetfactory':
    # Put students' puppetcode directories somewhere less distracting
    puppetcode => '/var/opt/puppetcode',
  }

  class { 'r10k':
    remote => 'https://github.com/puppetlabs-education/classroom-control.git',
  }
  include r10k::mcollective
  include puppet_enterprise::profile::mcollective::peadmin
}
