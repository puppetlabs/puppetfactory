class puppetfactory::first_module {
  # Classroom for First Module
  class { 'puppetfactory':
    # Put students' puppetcode directories somewhere obvious
    puppetcode       => '/var/puppetcode',
    map_environments => true,
    container_name   => 'centosagent',
  }
}
