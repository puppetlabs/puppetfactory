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
CODEDIR      =  OPTIONS['CODEDIR'] || '/etc/puppetlabs/code'
ENVIRONMENTS = "#{CODEDIR}/environments"

USERSUFFIX   =  OPTIONS['USERSUFFIX'] || 'puppetlabs.vm'
PUPPETCODE   =  OPTIONS['PUPPETCODE'] || '/var/opt/puppetcode'
HOOKS_PATH   =  OPTIONS['HOOKS_PATH'] || '/etc/puppetfactory/hooks'

MASTER_HOSTNAME = `hostname`.strip
DOCKER_GROUP    = OPTIONS['DOCKER_GROUP'] || 'docker'

MAP_ENVIRONMENTS = OPTIONS['MAP_ENVIRONMENTS'] || false
MAP_MODULEPATH   = OPTIONS['MAP_MODULEPATH']   || MAP_ENVIRONMENTS # maintain backwards compatibility

PE  = OPTIONS['PE'] || true

AUTH_INFO = OPTIONS['AUTH_INFO'] || {
  "ca_certificate_path" => "#{CONFDIR}/ssl/ca/ca_crt.pem",
  "certificate_path"    => "#{CONFDIR}/ssl/certs/#{MASTER_HOSTNAME}.pem",
  "private_key_path"    => "#{CONFDIR}/ssl/private_keys/#{MASTER_HOSTNAME}.pem"
}

CLASSIFIER_URL = OPTIONS['CLASSIFIER_URL'] || "http://#{MASTER_HOSTNAME}:4433/classifier-api"

class Puppetfactory  < Sinatra::Base
  set :views, File.dirname(__FILE__) + '/../views'
  set :public_folder, File.dirname(__FILE__) + '/../public'

  configure :production, :development do
    enable :logging

    # why do I have to do this? This page implies I shouldn't.
    # https://github.com/sinatra/sinatra#logging
    $logger = WEBrick::Log::new(LOGFILE, WEBrick::Log::DEBUG)

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
    # no need for all the returned status. That was a workaround for not having any real logging
    create(params[:username], params[:password])
  end

  delete '/api/users/:username' do
    delete(params[:username])
  end

  not_found do
    halt 404, 'page not found'
  end

  helpers do
    def load_users()
      # Get the users from the filesystem and look up their info
      users  = {}
      Dir.glob('/home/*').each do |path|
        username = File.basename path
        users[username] = load_user(username)
      end
      users
    end

    def load_user(username)
      # build the basic user object
      user = {
          :console  => "#{username}@#{USERSUFFIX}",
          :certname => "#{username}.#{USERSUFFIX}",
      }

      begin
        # Lookup the container by username and convert to json
        user_container = Docker::Container.get(username).json rescue {}

        user[:port]              = user_port(username)
        user[:container_status]  = user_container['State']
        user[:node_group_status] = node_group_status(username)
      rescue => ex
        $logger.error "Error loading user #{username}: #{ex.message}"
        $logger.debug ex.backtrace.join "\n"
      end
      user
    end

    def user_port(username)
      output = "3" + `id -u #{username}`.chomp
      $? == 0 ? output : nil
    end

    def create(username, password = 'puppet')
      username.downcase!

      begin
        $logger.info add_system_user(username,password)
        $logger.info create_container(username)
        if PE
          $logger.info add_console_user(username,password)
          $logger.info classify(username)
        end

        call_hooks(:create, username)

        { :status => :success, :message => "Created user #{username}."}.to_json
      rescue => e
        # TODO: should we call delete to cleanup?
        #delete(username) # Don't leave artifacts.
        $logger.error "Error creating #{username}: #{e.message}"
        {:status => :failure, :message => "Error creating #{username}: #{e.message}"}.to_json
      end
    end

    def delete(username)
      username.downcase!

      begin
        call_hooks(:delete, username)

        errors  = 0
        errors += 1 if failed? { remove_console_user(username) }
        errors += 1 if failed? { remove_container(username)    }
        errors += 1 if failed? { remove_node_group(username)   }
        errors += 1 if failed? { remove_system_user(username)  }

        if errors > 0
          {:status => :failure, :message => "#{errors} errors deleting user #{username}. See logs for details." }.to_json
        else
          {:status => :success, :message => "Deleted user #{username}."}.to_json
        end
      rescue => e
        {:status => :failure, :message => "Error deleting #{username}: #{e.message}" }.to_json
      end
    end

    def add_system_user(username, password)
      # ssh login user
      crypted = password.crypt("$5$a1")
      output = `adduser #{username} -p '#{crypted}' -G pe-puppet,#{DOCKER_GROUP} -m 2>&1`

      raise "Could not create system user #{username}: #{output}" unless $? == 0
      "System user #{username} created successfully"
    end

    def remove_system_user(username)
      output = `userdel -fr #{username}`

      raise "Could not remove system user #{username}: #{output}" unless $? == 0
      "System user #{username} removed successfully"
    end

    def add_console_user(username,password)
      # pe console user
      attributes = "display_name=#{username} roles=Operators email=#{username}@puppetlabs.vm password=#{password}"
      output     = `#{PUPPET} resource rbac_user #{username} ensure=present #{attributes} 2>&1`

      raise "Could not create PE Console user #{username}: #{output}" unless $? == 0
      "Console user #{username} created successfully"
    end

    def remove_console_user(username)
      output = `#{PUPPET} resource rbac_user #{username} ensure=absent 2>&1`

      raise "Could not remove PE Console user #{username}: #{output}" unless $? == 0
      "Console user #{username} removed successfully"
    end

    def console_user_status(username)
      output = `#{PUPPET} resource rbac_user #{username} 2>&1`

      raise "Could not query Puppet user #{username}: #{output}" unless $? == 0
      output =~ /present/
    end

    # TODO: refactor this method. It's too long and does too much
    def create_container(username)
      begin
        # Set up variables for the site.pp template
        servername = `/bin/hostname`.chomp
        @servername = servername
        @username = username
        puppetcode = PUPPETCODE
        map_environments = MAP_ENVIRONMENTS

        templates = "#{File.dirname(__FILE__)}/../templates"

        # Get the uid of the new user and set up URL
        port = user_port(username)

        binds = [
          "/var/yum:/var/yum",
          "/home/#{username}/share:/share",
          "/sys/fs/cgroup:/sys/fs/cgroup:ro"
        ]

        if MAP_ENVIRONMENTS then
          environment = "#{ENVIRONMENTS}/#{environment_name(username)}"

          # configure environment
          FileUtils.mkdir_p "#{environment}/manifests"
          FileUtils.mkdir_p "#{environment}/modules"

          File.open("#{environment}/manifests/site.pp", 'w') do |f|
            f.write ERB.new(File.read("#{templates}/site.pp.erb")).result(binding)
          end

          # Copy userprefs module into user environment
          FileUtils.cp_r("#{CODEDIR}/modules/userprefs", "#{environment}/modules/")

          # make sure the user and pe-puppet can access all the needful
          FileUtils.chown_R(username, 'pe-puppet', environment)
          FileUtils.chmod(0750, environment)
        end

        if MAP_MODULEPATH then
          binds.push("#{environment}:/root/puppetcode")
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
            "Privileged" => true,
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
          "Name" => "#{username}"
        )

        # Set container name to username
        container.rename(username)

        # Set default login to attach to container
        File.open("/home/#{username}/.bashrc", 'w') do |bashrc|
          bashrc.puts "docker exec -it #{container.id} su -"
          bashrc.puts "exit 0"
        end


        # Start container and copy puppet.conf in place
        container.start
        container.exec(["cp -f /share/puppet.conf #{CONFDIR}/puppet.conf"])

        # Create init scripts for container
        init_scripts(username)

      rescue => e
        raise "Error creating container #{username}: #{e.message}"
      end

      "Container #{username} created"
    end

    def remove_container(username)
      begin
        remove_init_scripts(username)

        container = Docker::Container.get(username)
        output = container.delete(:force => true)
      rescue => e
        raise "Error removing container #{username}: #{e.message}"
      end

      "Container #{username} removed"
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
      FileUtils.rm("/etc/init.d/docker-#{username}")
    end

    def classify(username, groups=[''])
      puppetclassify = PuppetClassify.new(CLASSIFIER_URL, AUTH_INFO)
      certname = "#{username}.#{USERSUFFIX}"
      groupstr = groups.join('\,')

      group_hash = {
        'name'               => certname,
        'environment'        => environment_name(username),
        'environment_trumps' => true,
        'parent'             => '00000000-0000-4000-8000-000000000000',
        'classes'            => {}
      }
      if MAP_ENVIRONMENTS then
        group_hash['rule'] = ['or', ['=', 'name', certname]]
      end

      begin
        puppetclassify.groups.create_group(group_hash)
      rescue => e
        raise "Could not create node group #{certname}: #{e.message}"
      end

      "Created node group #{certname} assigned to environment #{environment_name(username)}"
    end

    def remove_node_group(username)
      puppetclassify = PuppetClassify.new(CLASSIFIER_URL, AUTH_INFO)
      certname = "#{username}.#{USERSUFFIX}"

      begin
        group_id = puppetclassify.groups.get_group_id(certname)
        puppetclassify.groups.delete_group(group_id)
      rescue => e
        raise "Error removing node group #{certname}: #{e.message}"
      end

      "Node group #{certname} removed"
    end

    def node_group_status(username)
      puppetclassify = PuppetClassify.new(CLASSIFIER_URL, AUTH_INFO)
      certname = "#{username}.#{USERSUFFIX}"

      ! puppetclassify.groups.get_group_id(certname).nil?
    end

    def environment_name(username)
      if OPTIONS['PREFIX']
        "#{username}_production"
      else
        username
      end
    end

    def call_hooks(hook_type, username)
      # the .to_s allows us to accept strings or symbols
      Dir.glob("#{HOOKS_PATH}/#{hook_type.to_s}/*") do |hook|
        next unless File.file?(hook)
        next unless File.executable?(hook)

        begin
          $logger.info `#{hook} #{username}`
        rescue => e
          $logger.warn "Error running hook: #{hook}"
          $logger.debug e.message
        end
      end
    end

    # execute code and log its success or failure, then return a boolean success flag
    def failed?
      begin
        $logger.info yield
        false
      rescue => e
        $logger.error e.message
        true
      end
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
