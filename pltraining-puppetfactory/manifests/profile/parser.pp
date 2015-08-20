class puppetfactory::profile::parser {
  # Classroom for the parser course
  class { 'puppetfactory':
    # Put students' puppetcode directories somewhere less distracting
    puppetcode       => '/var/opt/puppetcode',
    map_environments => false,
  }
}
