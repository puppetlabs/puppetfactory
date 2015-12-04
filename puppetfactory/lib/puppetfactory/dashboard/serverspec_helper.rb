require 'serverspec'
require "docker"

set :backend, :docker
username = ENV['TARGET_HOST']

set :docker_container, Docker::Container.get(username).id
