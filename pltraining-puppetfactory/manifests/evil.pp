# Puppet doesn't give us the ability to override the default provider from
# within a module. This is evil hackery to modify the existing providers
# so that the classroom family of providers will be chosen by students, but
# so that the original provider will be used by the instructor
#
#                       DANGER WILL ROBINSON!
#
# This class will likely render the machine unusable for other purposes,
# especially if the module is later removed.
#
class puppetfactory::evil {
  file_line { 'hack yum package provider':
    path  => '/opt/puppet/lib/ruby/site_ruby/1.9.1/puppet/provider/package/yum.rb',
    line  => 'defaultfor :role => :instructor',
    match => '^\s*defaultfor',
  }

  file_line { 'hack redhat service provider':
    path  => '/opt/puppet/lib/ruby/site_ruby/1.9.1/puppet/provider/service/redhat.rb',
    line  => 'defaultfor :role => :instructor',
    match => '^\s*defaultfor',
  }
}
