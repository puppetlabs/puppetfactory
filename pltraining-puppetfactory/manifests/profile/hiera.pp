class puppetfactory::profile::hiera (
  $session_id = $puppetfactory::params::session_id,
) inherits puppetfactory::params {

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
