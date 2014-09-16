$:.unshift File.expand_path("../lib", __FILE__)
require 'date'

Gem::Specification.new do |s|
  s.name              = "puppetfactory"
  s.version           = '0.0.1'
  s.date              = Date.today.to_s
  s.summary           = "Stands up a graphical classroom manager with pseudo Puppet users."
  s.homepage          = "http://www.puppetlabs.com/education"
  s.email             = "ben.ford@puppetlabs.com"
  s.authors           = ["Ben Ford"]
  s.has_rdoc          = false
  s.require_path      = "lib"
  s.executables       = %w( puppetfactory )

  s.files             = %w( README.md LICENSE )
  s.files            += Dir.glob("lib/**/*")
  s.files            += Dir.glob("bin/**/*")
  s.files            += Dir.glob("views/**/*")
  s.files            += Dir.glob("public/**/*")
  s.files            += Dir.glob("templates/**/*")

  s.add_dependency      "sinatra", "~> 1.3"
  s.add_dependency      "json_pure"

  s.description       = <<-desc
  Puppetfactory creates a simulated Puppet Enterprise infrastructure on the
  classroom server. Each student has an environment providing a sandboxed
  directory for Puppet code and configuration. The classroom server will also
  be running the unmodified Puppet Enterprise Console with an account for each
  student.

  Pseudo tools are provided to allow students to manage simulated hosts,
  packages, services, and users. These tools have been integrated into the
  Puppet Enterprise configuration, so students may interact with these simulated
  resources exactly like any other resource.

  MCollective servers are started up for each student and can be used with Live
  Management exactly as in production.
  desc

end
