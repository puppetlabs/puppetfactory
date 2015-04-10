class puppetfactory::intro {
  # Classroom for Intro to puppet course
  class { 'puppetfactory':
    # Put students' puppetcode directories somewhere obvious
    puppetcode => '/root/puppetcode',
  }
}
