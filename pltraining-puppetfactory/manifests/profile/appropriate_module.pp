class puppetfactory::profile::appropriate_module (
  $session_id = $puppetfactory::params::session_id,
) inherits puppetfactory::params {
  # Classroom for Appropriate Module Design course
  contain puppetfactory::profile::default
}
