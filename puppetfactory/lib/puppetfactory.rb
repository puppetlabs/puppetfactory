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
require 'puppetclassify'
require 'docker'

OPTIONS = YAML.load_file('/etc/puppetfactory.yaml') rescue nil

AUTH_INFO = OPTIONS['AUTH_INFO'] || {
  "ca_certificate_path" => "/opt/puppet/share/puppet-dashboard/certs/ca_cert.pem",
  "certificate_path"    => "/opt/puppet/share/puppet-dashboard/certs/pe-internal-dashboard.cert.pem",
  "private_key_path"    => "/opt/puppet/share/puppet-dashboard/certs/pe-internal-dashboard.private_key.pem"
}

CLASSIFIER_URL = OPTIONS['CLASSIFIER_URL'] || 'http://master.puppetlabs.vm:4433/classifier-api'

PUPPET    =  OPTIONS['PUPPET'] || '/opt/puppet/bin/puppet'
RAKE      =  OPTIONS['RAKE'] || '/opt/puppet/bin/rake'
DASH_PATH =  OPTIONS['DASH_PATH'] || '/opt/puppet/share/puppet-dashboard'
RAKE_API  = "#{RAKE} -f #{DASH_PATH}/Rakefile RAILS_ENV=production"

DOCROOT   =  OPTIONS['DOCROOT'] || '/opt/puppetfactory'           # where templates and public files go
LOGFILE   =  OPTIONS['LOGFILE'] || '/var/log/puppetfactory'
CERT_PATH =  OPTIONS['CERT_PATH'] || 'certs'
USER      =  OPTIONS['USER'] || 'admin'
PASSWORD  =  OPTIONS['PASSWORD'] || 'admin'
CONTAINER_NAME =  OPTIONS['CONTAINER_NAME'] || 'centosagent'

CONFDIR      =  OPTIONS['CONFDIR'] || '/etc/puppetlabs/puppet'
ENVIRONMENTS = "#{CONFDIR}/environments"
USERSUFFIX   =  OPTIONS['USERSUFFIX'] || 'puppetlabs.vm'
PUPPETCODE   =  OPTIONS['PUPPETCODE'] || '/var/opt/puppetcode'

MASTER_HOSTNAME = `hostname`.strip
DOCKER_GROUP = OPTIONS['DOCKER_GROUP'] || 'docker'

MAP_ENVIRONMENTS = OPTIONS['MAP_ENVIRONMENTS'] || false
PE  = OPTIONS['PE'] || true

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

  get '/new/:username' do |username|
    protected!
    create(username)
  end

  post '/new' do
    # protected!
    create(params[:username], params[:password])
  end

  not_found do
    halt 404, 'page not found'
  end

  # RESTful API endpoints

  # Return details for all users as JSON
  get '/api/users' do
    load_users().to_json
  end

  # Return details for single user
  get '/api/users/:username' do
    username = params[:username]
    load_user(username).to_json
  end

  get '/api/users/:username/port' do
    user_port(params[:username])
  end

  get '/api/users/:username/node_group_status' do
    node_group_status(params[:username]).to_json
  end


  get '/api/users/:username/console_user_status' do
    console_user_status(params[:username]).to_json
  end

  post '/api/users' do
    user_status = {}
    username = params[:username]
    password = params[:password]
    user_status = {
      :system_user_status => add_system_user(username,password),
      :console_user_status => add_console_user(username,password),
      :container_status => create_container(username.downcase),
      :node_group_status => classify(username.downcase),
    }
    user_status.to_json
  end

  delete '/api/users/:username' do
    delete(params[:username])
  end

  helpers do
    def load_users()
      # Loop through the containers to get the full data 
      # rather than just the reference
      containers = []
      Docker::Container.all().each do |container|
        containers.push(container.json)
      end

      users  = {}
      Dir.glob('/home/*').each do |path|
        username = File.basename path
        user_container = ""
        containers.each do |container|
          if container['Name'] = "/" + username
            user_container = container
          end
        end
        users[username] = load_user(username, user_container)
      end
      users
    end

    def load_user(username, user_container)

      user = {}
      certname = "#{username}.#{USERSUFFIX}"
      console  = "#{username}@#{USERSUFFIX}"

      user = {
        :console  => console,
        :port     => user_port(username),
        :certname => certname,
        :container_status   => user_container['State'],
        :node_group_status => node_group_status(username),
      }
      user
    end

    def user_port(username)
      output = "3" + `id -u #{username}`.chomp
      $? == 0 ? output : nil
    end

    def create(username, password = 'puppet')
      begin
        add_system_user(username,password)
        create_container(username.downcase)
        if PE
          add_console_user(username,password)
          classify(username.downcase)
        end

        {:status => :success, :message => "Created user #{username.downcase}."}.to_json
      rescue Exception => e
        {:status => :failure, :message => e.message}.to_json
      end
    end

    def delete(username)
      remove_system_user(username)
      remove_console_user(username)
      remove_container(username)
      remove_node_group(username)
    end

    def add_system_user(username, password)
      # ssh login user
      crypted = password.crypt("$5$a1")
      output = `adduser #{username} -p '#{crypted}' -G pe-puppet,#{DOCKER_GROUP} -m 2>&1`
      $? == 0 ? "User #{username} created successfully" : "Could not create login user #{username}: #{output}"
    end

    def remove_system_user(username)
      output = `userdel #{username} && rm -rf /home/#{username}`
      $? == 0 ? "User #{username} removed successfully" : "Could not remove login user #{username}: #{output}"
    end

    def add_console_user(username,password)
      # pe console user
      attributes = "display_name=#{username} roles=Operators email=#{username}@puppetlabs.vm password=#{password}"
      output     = `#{PUPPET} resource rbac_user #{username} ensure=present #{attributes} 2>&1`
      $? == 0 ? "Console user #{username} created successfully" :  "Could not create PE Console user #{username}: #{output}"
    end

    def remove_console_user(username)
      output     = `#{PUPPET} resource rbac_user #{username} ensure=absent 2>&1`
      $? == 0 ? "Console user #{username} removed successfully" :  "Could not remove PE Console user #{username}: #{output}"
    end

    def console_user_status(username)
      output     = `#{PUPPET} resource rbac_user #{username} 2>&1`
      if $? == 0 then
        output =~ /present/ ? true : false
      else
        nil
      end
    end

    def create_container(username)
      @username   = username
      @servername = `/bin/hostname`.chomp

      templates = "#{File.dirname(__FILE__)}/../templates"

      # Get the uid of the new user and set up URL
      port = user_port(username)

      binds = [
        "/var/yum:/var/yum",
        "/home/#{username}/share:/share",
        "/sys/fs/cgroup:/sys/fs/cgroup:ro"
      ]
      volumes = {
        "/share" => "/home/#{username}/share",
        "/var/yum" => "/var/yum",
        "/sys/fs/cgroup" => "/sys/fs/cgroup:ro"
      }

      if MAP_ENVIRONMENTS then
        File.open("#{ENVIRONMENTS}/#{username}/manifests/site.pp", 'w') do |f|
          f.write ERB.new(File.read("#{templates}/site.pp.erb")).result(binding)
        end
        # configure environment
        FileUtils.mkdir_p "#{ENVIRONMENTS}/#{username}/manifests"
        FileUtils.mkdir_p "#{ENVIRONMENTS}/#{username}/modules"

        # make sure the user and pe-puppet can access all the needful
        FileUtils.chown_R username, 'pe-puppet', "#{ENVIRONMENTS}/#{username}"
        FileUtils.chmod 0750, "#{ENVIRONMENTS}/#{username}"

        binds.push("/etc/puppetlabs/puppet/environments/#{username}:/root/puppetcode")
        volumes["/root/puppetcode"] = "/etc/puppetlabs/puppet/environments/#{username}"
      end

      # Create shared folder to map and create puppet.conf
      FileUtils.mkdir_p "/home/#{username}/share"
      File.open("/home/#{username}/share/puppet.conf","w") do |f|
        f.write ERB.new(File.read("#{templates}/puppet.conf.erb")).result(binding)
      end

      # Create container with hostname set for username with port 80 mapped to 3000 + uid
      container = Docker::Container.create(
        "Cmd" => [
          "/sbin/init"
        ],
        "Domainname" => "puppetlabs.vm",
        "Env" => [
          "RUNLEVEL=3",
          "PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin",
          "HOME=/root/",
          "TERM=xterm"
        ],
        "ExposedPorts" => {
          "80/tcp" => {
          }
        },
        "Hostname" => "#{username}",
        "Image" => "#{CONTAINER_NAME}",
        "HostConfig" => {
          "Binds" => binds,
          "ExtraHosts" => [
            "#{MASTER_HOSTNAME} puppet:172.17.42.1"
          ],
          "PortBindings" => {
            "80/tcp" => [
              {
                "HostPort" => "#{port}"
              }
            ]
          },
        },
        "Name" => "#{username}",
        "Volumes" => volumes

      )


      # Set default login to attach to container
      File.open("/home/#{username}/.bashrc", 'w') do |bashrc|
        bashrc.puts "docker exec -it #{container.id} su -"
        bashrc.puts "exit 0"
      end


      # Copy userprefs module into user environment
      if MAP_ENVIRONMENTS then
        `cp -r #{ENVIRONMENTS}/production/modules/userprefs #{ENVIRONMENTS}/#{username}/modules`
        `chown -R #{username}:pe-puppet #{ENVIRONMENTS}/#{username}`
      end

      # Start container and copy puppet.conf in place
      container.start
      container.exec('cp -f /share/puppet.conf /etc/puppetlabs/puppet/puppet.conf')

      # Create init scripts for container
      init_scripts(username.downcase)
    end


    def remove_container(username)
      remove_init_scripts(username)
      #`rm -rf #{ENVIRONMENTS}/#{username}`
      output = `docker kill #{username} && docker rm #{username}`
      $? == 0 ? "Container #{username} removed" : "Error removing container #{username}" 
    end

    def init_scripts(username)
      templates = "#{File.dirname(__FILE__)}/../templates"
      File.open("/etc/init.d/docker-#{username}","w") do |f|
        f.write ERB.new(File.read("#{templates}/init_scripts.erb")).result(binding)
      end
      File.chmod(0755, "/etc/init.d/docker-#{username}")
      `chkconfig docker-#{username} on`
    end

    def remove_init_scripts(username)
      `chkconfig docker-#{username} off`
      `rm /etc/init.d/docker-#{username}`
    end

    def classify(username, groups=[''])
      puppetclassify = PuppetClassify.new(CLASSIFIER_URL, AUTH_INFO)
      certname = "#{username}.#{USERSUFFIX}"
      groupstr = groups.join('\,')

      group_hash = {
        'name'               => certname,
        'environment'        => username,
        'environment_trumps' => true,
        'parent'             => '00000000-0000-4000-8000-000000000000',
        'classes'            => {}
      }
      if MAP_ENVIRONMENTS then
        group_hash['rule'] = ['or', ['=', 'name', certname]]
      end
      
      puppetclassify.groups.create_group(group_hash)

    end

    def remove_node_group(username)
      puppetclassify = PuppetClassify.new(CLASSIFIER_URL, AUTH_INFO)
      certname = "#{username}.#{USERSUFFIX}"
      group_id = puppetclassify.groups.get_group_id(certname)
      output = puppetclassify.groups.delete_group(group_id)
      $? == 0 ? "Node group #{certname} removed" : "Error removing node group #{certname} : #{output}" 
    end

    def node_group_status(username)
      puppetclassify = PuppetClassify.new(CLASSIFIER_URL, AUTH_INFO)
      certname = "#{username}.#{USERSUFFIX}"
      output = puppetclassify.groups.get_group_id(certname)
      output != nil ? true : false
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
