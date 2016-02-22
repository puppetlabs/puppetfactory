class puppetfactory::profile::hiera (
  $session_id = $puppetfactory::params::session_id,
) inherits puppetfactory::params {
  contain puppetfactory::profile::default
}
