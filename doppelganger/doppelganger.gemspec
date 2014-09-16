require 'date'

Gem::Specification.new do |s|
  s.name              = "doppelganger"
  s.version           = '0.0.1'
  s.date              = Date.today.to_s
  s.summary           = "A simplistic non-root user/package/service management simulation."
  s.homepage          = "http://github.com/binford2k/doppelganger"
  s.email             = "education@puppetlabs.com"
  s.authors           = ["Ben Ford"]
  s.has_rdoc          = false
  s.require_path      = "lib"
  s.executables       = %w( pl-package pl-service pl-user )
  s.files             = %w( README.md LICENSE )
  s.files            += Dir.glob("lib/**/*")
  s.files            += Dir.glob("bin/**/*")
  s.description       = <<-desc
  A simplistic classroom non-root user/package/service management simulation.

  All this does is provide a quick library and some tools to interact with
  stupid-simple resource databases to simulate working with resources that
  typically requires root access. It's designed for use with the Puppet Labs
  Introduction to Puppet training class and has providers enabling the use
  of this simulation with the standard Puppet Resource Abstraction Layer.
  desc
end