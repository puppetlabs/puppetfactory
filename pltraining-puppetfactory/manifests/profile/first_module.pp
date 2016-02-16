class puppetfactory::profile::first_module (
  $session_id = $puppetfactory::params::session_id,
) inherits puppetfactory::params {
  # Classroom for First Module
  class { 'puppetfactory':
    # Put students' puppetcode directories somewhere obvious
    puppetcode       => '/var/puppetcode',
    map_environments => true,
    container_name   => 'centosagent',
    session_id       => $session_id,
  }

  class { 'puppetfactory::profile::showoff':
    password => $session_id,
  }
}
