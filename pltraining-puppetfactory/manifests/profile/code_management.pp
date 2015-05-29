class puppetfactory::profile::code_management {
  # Classroom for the codemanagement course
  class { 'puppetfactory':
    # Put students' puppetcode directories somewhere less distracting
    puppetcode => '/var/opt/puppetcode',
  }
}
