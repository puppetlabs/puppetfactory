require 'serverspec'
require "docker"

set :backend, :docker
username = ENV['TARGET_HOST']

set :docker_container, Docker::Container.get(username).id

# Serverspec types and matchers below. Until we decide to gemify them :)

# This defines the method used to build the test case
def puppet
  Serverspec::Type::Puppet.new()
end

module Serverspec::Type
  class Puppet < Base

    def initialize
      super
      return unless @settings.nil?

      @settings = {}
      data = @runner.run_command('puppet agent --configprint all').stdout
      data.split("\n").each do |line|
        key, value = line.split(' = ')
        @settings[key.to_sym] = value

        self.class.send(:define_method, key) { value }
        #define_method(key) { value }
      end
    end

    def to_s
      'Puppet managed attributes'
    end

    def enabled?
      not disabled?
    end

    def disabled?
      @runner.check_file_is_file(@settings[:agent_disabled_lockfile])
    end

    def has_signed_cert?
      @runner.check_file_is_file(@settings[:hostcert])
    end

    def has_run_puppet?
      @runner.check_file_is_file(@settings[:lastrunreport])
    end

    def classified_with?(klass)
      #@runner.check_file_contains(@settings[:classfile], /^klass$/)
      @classfile ||= @runner.get_file_content(@settings[:classfile]).stdout
      @classfile =~ /^#{klass}$/
    end

    def has_resource?(resource)
      #@runner.check_file_contains(@settings[:resourcefile], resource)
      @resourcefile ||= @runner.get_file_content(@settings[:resourcefile]).stdout

      case resource
      when String
        @resourcefile.include? resource
      when Regexp
        @resourcefile =~ /^#{resource}$/
      else
        false
      end
    end
  end
end

RSpec::Matchers.define :manage_resource do |resource|
  match do |subject|
    if subject.class.name == 'Serverspec::Type::Puppet'
      subject.has_resource?(resource)
    else
      raise "The 'manage_resource' matcher does not support #{subject.class.name}."
    end
  end
end
