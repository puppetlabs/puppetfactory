require 'yaml'
require 'puppetfactory'
require 'json'
require 'httparty'

class Puppetfactory
  class Cli
    def initialize(options = {})
      if options[:server]
        @server = options[:server]
      else
        @server = 'localhost'
      end
      @server = "http://#{@server}:#{options[:port]}" unless @server.start_with? 'http'
      @master = options[:master]
      @debug  = options[:debug]
    end

    def list()
      begin
        puts ' Username        Sandbox URL                   Certname                 Container | Node Group'
        response = HTTParty.get("#{@server}/api/users")
        raise "PuppetFactory service not responding: #{@server}" unless response.code == 200

        JSON.parse(response.body).each do |user, params|
          container = params['container_status']['Dead'] ? 'X' : '+' rescue '?'
          nodegroup = params['node_group_url'].nil?      ? 'X' : '+'
          printf("%-14s  https://%s%10s        %-25s     %1s          %1s\n", user, @master, params['url'], params['certname'], container, nodegroup)
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

        data = JSON.parse(response.body)
        raise data['message'] unless data['status'] == 'success'

        puts "User #{user} created."
      rescue => e
        puts "API error creating user #{user}: #{e.message}"
        puts e.backtrace if @debug
      end
    end

    def delete(user)
      begin
        response = HTTParty.delete("#{@server}/api/users/#{user}")
        raise "Puppetfactory error: #{response.body}" unless response.code == 200

        data = JSON.parse(response.body)
        raise data['message'] unless data['status'] == 'success'

        puts "User #{user} deleted."
      rescue => e
        puts "API error deleting user #{user}: #{e.message}"
        puts e.backtrace if @debug
      end
    end

    def repair(user)
      begin
        response = HTTParty.put("#{@server}/api/users/#{user}",
                                { body: {
                                    username: user,
                                    action: "repair"}
                                })
        raise "Puppetfactory error: #{response.body}" unless response.code == 200

        data = JSON.parse(response.body)
        raise data['message'] unless data['status'] == 'success'

        puts "User #{user} repaired."
      rescue => e
        puts "API error repair user #{user}: #{e.message}"
        puts e.backtrace if @debug
      end
    end
    def redeploy(user)
      begin
        response = HTTParty.put("#{@server}/api/users/#{user}",
                                { body: {
                                    username: user,
                                    action: "redeploy"}
                                })
        raise "Puppetfactory error: #{response.body}" unless response.code == 200

        data = JSON.parse(response.body)
        raise data['message'] unless data['status'] == 'success'

        puts "User #{user} repaired."
      rescue => e
        puts "API error redeploying environment #{user}: #{e.message}"
        puts e.backtrace if @debug
      end
    end

    def test()
      require 'pry'
      binding.pry
    end
  end
end
