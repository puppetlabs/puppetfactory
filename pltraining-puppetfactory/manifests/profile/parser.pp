class puppetfactory::profile::parser (
  $session_id = $puppetfactory::params::session_id,
) inherits puppetfactory::params {
  # Classroom for the parser course
  class { 'puppetfactory':
    # Put students' puppetcode directories somewhere less distracting
    puppetcode       => '/var/opt/puppetcode',
    map_environments => false,
    session_id       => $session_id,
  }

  class { 'puppetfactory::profile::showoff':
    password => $session_id,
  }
}
