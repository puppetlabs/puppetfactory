class puppetfactory::profile::intro (
  $session_id = $puppetfactory::params::session_id,
) inherits puppetfactory::params {
  # Classroom for Intro to puppet course
  contain puppetfactory::profile::default
}
