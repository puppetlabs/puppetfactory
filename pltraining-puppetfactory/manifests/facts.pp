# This class writes out some moderately interesting external facts. These are
# useful for demonstrating structured facts.
#
# Their existence also serves as a marker that initial provisioning has taken
# place, for the small handful of items that we only want to manage once.
#
class puppetfactory::facts (
  $coursename
) {
  file { [ '/etc/puppetlabs/facter/', '/etc/puppetlabs/facter/facts.d/' ]:
    ensure => directory,
  }

  file { '/etc/puppetlabs/facter/facts.d/puppetlabs.txt':
    ensure  => file,
    content => template('puppetfactory/facts.txt.erb'),
  }
}