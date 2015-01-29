#! /usr/bin/env ruby

require 'rubygems'
require 'sinatra/base'
require 'webrick'
# require 'webrick/https'
# require 'openssl'
require 'resolv'
require 'json'
require 'fileutils'
require 'erb'
require 'yaml'

PUPPET    = '/opt/puppet/bin/puppet'
RAKE      = '/opt/puppet/bin/rake'
DASH_PATH = '/opt/puppet/share/puppet-dashboard'
RAKE_API  = "#{RAKE} -f #{DASH_PATH}/Rakefile RAILS_ENV=production"

DOCROOT   = '/opt/puppetfactory'            # where templates and public files go
LOGFILE   = '/var/log/puppetfactory'
CERT_PATH = 'certs'
USER      = 'admin'
PASSWORD  = 'admin'
CONTAINER_NAME = 'puppetfactory'

CONFDIR      = '/etc/puppetlabs/puppet'
ENVIRONMENTS = "#{CONFDIR}/environments"
USERSUFFIX   = 'puppetlabs.vm'

class Puppetfactory  < Sinatra::Base
    set :views, File.dirname(__FILE__) + '/../views'
    set :public_folder, File.dirname(__FILE__) + '/../public'

    configure :production, :development do
      enable :logging

      # why do I have to do this? This page implies I shouldn't.
      # https://github.com/sinatra/sinatra#logging
      set :logger,    WEBrick::Log::new(LOGFILE, WEBrick::Log::DEBUG)
      set :semaphore, Mutex.new
    end

    get '/' do
      erb :index
    end

    get '/home' do
      erb :home
    end

    get '/users' do
      protected!
      @users = load_users()
      erb :users
    end

    get '/login' do
      protected!
      erb :login
    end

    get '/reference' do
      erb :reference
    end

    get '/new/:username' do |username|
      protected!
      create(username)
    end

    post '/new' do
      protected!
      create(params[:username], params[:password])
    end

    not_found do
      halt 404, 'page not found'
    end

    helpers do

      def load_users()
        status = {}
        users  = {}

        # build a quick list of all certificate statuses
        `/opt/puppet/bin/puppet cert list --all`.split.each do |line|
          status[$2] = $1 if line =~ /^([+-])?.*"([\w\.]*)"/
        end

        Dir.glob('/home/*').each do |path|
          username = File.basename path
          certname = "#{username}.#{USERSUFFIX}"
          console  = "#{username}@#{USERSUFFIX}"

          begin
            data    = YAML.load_file("/home/#{username}/.puppet/var/state/last_run_summary.yaml")
            lastrun = Time.at(data['time']['last_run'])
          rescue Exception
            lastrun = :never
          end

          users[username] = {
            :status   => status[certname],
            :console  => console,
						:port			=> port,
            :certname => certname,
            :lastrun  => lastrun
          }
        end

        users
      end

      def create(username, password = 'puppet')
        begin
          adduser(username, password)
          skeleton(username)
          classify(username)
          sign(username)
          restartmco()

          {:status => :success, :message => "Created user #{username}."}.to_json
        rescue Exception => e
          {:status => :failure, :message => e.message}.to_json
        end
      end

      def adduser(username, password)
        crypted = password.crypt("$5$a1")

        # ssh login user
        output = `adduser #{username} -p '#{crypted}' -G pe-puppet,docker -m 2>&1`
        raise "Could not create login user #{username}: #{output}" unless $? == 0

        # Get the uid of the new user and set up URL
        port = "3" + `id -u #{username}`.chomp

        # Create container with hostname set for username with port 80 mapped to 3000 + uid
        `docker run --privileged --name="#{username}" -p #{port}:80 -h #{username}.#{USERSUFFIX} -d #{CONTAINER_NAME} /sbin/init`

        # Set default login to attache to container
        bashrc = File.open("/home/#{username}/.bashrc", 'w')
        bashrc.puts "docker exec -it #{username} bash"
        bashrc.puts "exit 0"
        bashrc.close

        # Add docker route ip as master.puppetlabs.vm in the hosts file
        `docker exec #{username} puppet apply -e 'host { "master.puppetlabs.vm": ensure=>present, host_aliases=>["master","puppet"], ip=>"172.17.42.1", target=>"/etc/hosts" }'`

        # pe console user
        attributes = "display_name=#{username} roles=Operators email=#{username}@puppetlabs.vm password=#{password}"
        output     = `#{PUPPET} resource rbac_user #{username} ensure=present #{attributes} 2>&1`

        raise "Could not create PE Console user #{username}: #{output}" unless $? == 0
      end

      def skeleton(username)
        @username   = username
        @amqpasswd  = key = File.read('/etc/puppetlabs/mcollective/credentials')
        @servername = `/bin/hostname`.chomp

        templates = "#{File.dirname(__FILE__)}/../templates"

        # configure environment
        FileUtils.mkdir_p "#{ENVIRONMENTS}/#{username}/manifests"
        FileUtils.mkdir_p "#{ENVIRONMENTS}/#{username}/modules"

        File.open("#{ENVIRONMENTS}/#{username}/manifests/site.pp", 'w') do |f|
          f.write ERB.new(File.read("#{templates}/site.pp.erb")).result(binding)
        end

#        FileUtils.mkdir_p "/home/#{username}/.puppet/"

#        FileUtils.ln_s "#{ENVIRONMENTS}/#{username}/manifests", "/home/#{username}/.puppet/manifests"
#        FileUtils.ln_s "#{ENVIRONMENTS}/#{username}/modules", "/home/#{username}/.puppet/modules"
#        FileUtils.ln_s "/home/#{username}/.puppet", "/home/#{username}/puppet"

        # configure puppet agent
#        File.open("/home/#{username}/.puppet/puppet.conf", 'w') do |f|
#          f.write ERB.new(File.read("#{templates}/puppet.conf.erb")).result(binding)
#        end

        # configure mcollective server
        FileUtils.mkdir_p "/home/#{username}/etc"
        FileUtils.mkdir_p "/home/#{username}/var/log/pe-mcollective"
        FileUtils.cp_r('/etc/puppetlabs/mcollective', "/home/#{username}/etc/mcollective")
        File.open("/home/#{username}/etc/mcollective/server.cfg", 'w') do |f|
          f.write ERB.new(File.read("#{templates}/server.cfg.erb")).result(binding)
        end

        # make sure the user and pe-puppet can access all the needful
        FileUtils.chown_R username, 'pe-puppet', "#{ENVIRONMENTS}/#{username}"
        FileUtils.chown_R username, 'pe-puppet', "/home/#{username}"
        FileUtils.chmod 0750, "#{ENVIRONMENTS}/#{username}"
        FileUtils.chmod 0750, "/home/#{username}"
      end

      def classify(username, groups=['no mcollective'])
        certname = "#{username}.#{USERSUFFIX}"
        groupstr = groups.join('\,')

        output = `#{RAKE_API} node:add['#{certname}','#{groupstr}'] 2>&1`
        raise "Error classifying #{certname}: #{output}" unless $? == 0
      end

      def sign(username)
        output = `sudo -iu #{username} #{PUPPET} agent -t 2>&1`
        raise "Error creating certificates: #{output}, exit code #{$?}" unless $? == 256

        output = `#{PUPPET} cert sign #{username}.puppetlabs.vm 2>&1`
        raise "Error signing #{username}: #{output}" unless $? == 0
      end

      def restartmco()
        system('service user-mcollective restart')
      end

      # Basic auth boilerplate
      def protected!
        unless authorized?
          response['WWW-Authenticate'] = %(Basic realm="Restricted Area")
          throw(:halt, [401, "Not authorized\n"])
        end
      end

      def authorized?
        @auth ||=  Rack::Auth::Basic::Request.new(request.env)
        @auth.provided? && @auth.basic? && @auth.credentials && @auth.credentials == [USER, PASSWORD]
      end

    end
end
