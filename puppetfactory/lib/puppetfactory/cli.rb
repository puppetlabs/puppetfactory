require 'yaml'
require 'puppetfactory'
require 'json'
require 'httparty'

class Puppetfactory
  class Cli
    def initialize(options = {})
      config = YAML.load_file('/etc/puppetfactory.yaml') rescue nil

      if options[:server]
        @server = options[:server]
      elsif config['SERVER']
        @server = config['SERVER']
      else
        @server = 'localhost'
      end
      @server = "http://#{@server}" unless @server.start_with? 'http'

      @debug = options[:debug]
    end

    def list()
      begin
        puts ' Username        Sandbox URL                   Certname                 Container | Node Group'
        response = HTTParty.get("#{@server}/api/users")
        raise "PuppetFactory service not responding: #{@server}" unless response.code == 200

        JSON.parse(response.body).each do |user, params|
          container = params['container_status']['Dead'] ? 'X' : '+' rescue '?'
          nodegroup = params['node_group_status']        ? '+' : 'X'
          printf("%-14s  #{@server}:%5s        %-25s     %1s          %1s\n", user, params['port'], params['certname'], container, nodegroup)
        end
      rescue => e
        puts "API error listing users: #{e.message}"
        puts e.backtrace if @debug
      end
    end

    def create(user, password)
      begin
        params = {
          body: {
            username: user,
            password: password
          }
        }
        response = HTTParty.post("#{@server}/api/users", params)
        raise "PuppetFactory error: #{response.body}" unless response.code == 200

        puts "User #{user} created."
      rescue => e
        puts "API error creating user #{user}: #{e.message}"
        puts e.backtrace if @debug
      end
    end

    def delete(user)
      begin
        response = HTTParty.delete("#{@server}/api/users/#{user}")
        raise "No such user" unless response.code == 200

        puts "User #{user} deleted."
      rescue => e
        puts "API error deleting user #{user}: #{e.message}"
        puts e.backtrace if @debug
      end
    end

    def test()
      require 'pry'
      binding.pry
    end
  end
end