class puppetfactory::profile::intro {
  # Classroom for Intro to puppet course
  class { 'puppetfactory':
    # Put students' puppetcode directories somewhere obvious
    puppetcode       => '/root/puppetcode',
    map_environments => true,
    container_name   => 'centosagent',
  }
}
