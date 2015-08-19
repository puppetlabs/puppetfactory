class puppetfactory::profile::parser_agent {
  file { '/usr/local/bin/course_selector':
    ensure => present,
    mode   => 755,
    source => '/usr/src/courseware-lms-content/scripts/course_selector.rb',
    require => Vcsrepo['/usr/src/courseware-lms-content'],
  }
  # Clone the courseware and copy example files to appropriate places
  vcsrepo { '/usr/src/courseware-lms-content':
    ensure   => present,
    provider => git,
    source   => 'https://github.com/puppetlabs/courseware-lms-content.git',
  }
}
