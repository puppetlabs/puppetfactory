class puppetfactory::profile::appropriate_module (
  $session_id = $puppetfactory::params::session_id,
) inherits puppetfactory::params {
  # Classroom for Appropriate Module Design course
  class { 'puppetfactory':
    # Put students' puppetcode directories somewhere obvious
    puppetcode       => '/root/puppetcode',
    map_environments => true,
    container_name   => 'centosagent',
    session_id       => $session_id,
  }

  class { 'puppetfactory::profile::showoff':
    password => $session_id,
  }
}
