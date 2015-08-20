class puppetfactory::profile::hiera {
  # Classroom for the hiera course
  class { 'puppetfactory':
    # Put students' puppetcode directories somewhere less distracting
    puppetcode       => '/var/opt/puppetcode',
    map_environments => false,
  }
}
