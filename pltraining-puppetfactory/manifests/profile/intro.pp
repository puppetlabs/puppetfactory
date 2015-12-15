class puppetfactory::profile::intro (
  $session_id = $puppetfactory::params::session_id,
) inherits puppetfactory::params {
  # Classroom for Intro to puppet course
  class { 'puppetfactory':
    # Put students' puppetcode directories somewhere obvious
    puppetcode       => '/root/puppetcode',
    map_environments => true,
    container_name   => 'centosagent',
    session_id       => $session_id,
  }
}
