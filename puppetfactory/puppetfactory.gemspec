$:.unshift File.expand_path("../lib", __FILE__)
require 'date'

Gem::Specification.new do |s|
  s.name              = "puppetfactory"
  s.version           = '0.1.4'
  s.date              = Date.today.to_s
  s.summary           = "Stands up a graphical classroom manager with containerized puppet agents."
  s.homepage          = "http://www.puppetlabs.com/education"
  s.email             = "ben.ford@puppetlabs.com"
  s.authors           = ["Ben Ford","Josh Samuelson"]
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
  s.add_dependency      "puppetclassify", ">= 0.1.1"

  s.description       = <<-desc
  Puppetfactory creates a Puppet Enterprise infrastructure on the classroom server. 
  Each student has a container for Puppet code and configuration linked to their
  environment on the master.  The containers are built on docker and duplicate most 
  of the behavior of a full VM or bare-metal system.  The classroom server will also 
  be running the unmodified Puppet Enterprise Console with an account for each student.
  desc
end
