class puppetfactory::profile::appropriate_module {
  # Classroom for Appropriate Module Design course
  class { 'puppetfactory':
    # Put students' puppetcode directories somewhere obvious
    puppetcode       => '/root/puppetcode',
    map_environments => true,
    container_name   => 'centosagent',
  }
}
