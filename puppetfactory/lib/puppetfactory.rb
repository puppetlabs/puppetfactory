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
require 'time'
require 'puppetclassify'
require 'docker'
require 'rest-client'

OPTIONS = YAML.load_file('/etc/puppetfactory.yaml') rescue {}

PUPPET    =  OPTIONS['PUPPET'] || '/opt/puppet/bin/puppet'
RAKE      =  OPTIONS['RAKE'] || '/opt/puppet/bin/rake'
DASH_PATH =  OPTIONS['DASH_PATH'] || '/opt/puppet/share/puppet-dashboard'
RAKE_API  = "#{RAKE} -f #{DASH_PATH}/Rakefile RAILS_ENV=production"

DOCROOT   =  OPTIONS['DOCROOT'] || '/opt/puppetfactory'           # where templates and public files go
LOGFILE   =  OPTIONS['LOGFILE'] || '/var/log/puppetfactory'
CERT_PATH =  OPTIONS['CERT_PATH'] || 'certs'

USER      =  OPTIONS['USER']     || 'admin'
PASSWORD  =  OPTIONS['PASSWORD'] || 'admin'
SESSION   =  OPTIONS['SESSION']  || '12345'

CONTAINER_NAME =  OPTIONS['CONTAINER_NAME'] || 'centosagent'

CONFDIR      =  OPTIONS['CONFDIR'] || '/etc/puppetlabs/puppet'
CODEDIR      =  OPTIONS['CODEDIR'] || '/etc/puppetlabs/code'
ENVIRONMENTS = "#{CODEDIR}/environments"

USERSUFFIX   =  OPTIONS['USERSUFFIX'] || 'puppetlabs.vm'
PUPPETCODE   =  OPTIONS['PUPPETCODE'] || '/var/opt/puppetcode'
HOOKS_PATH   =  OPTIONS['HOOKS_PATH'] || '/etc/puppetfactory/hooks'

MASTER_HOSTNAME = OPTIONS['PUPPETMASTER'] || `hostname`.strip
DOCKER_GROUP    = OPTIONS['DOCKER_GROUP'] || 'docker'
DOCKER_IP       = OPTIONS['DOCKER_IP'] || `facter ipaddress_docker0`.strip

MAP_ENVIRONMENTS = OPTIONS['MAP_ENVIRONMENTS'] || false
MAP_MODULEPATH   = OPTIONS['MAP_MODULEPATH']   || MAP_ENVIRONMENTS # maintain backwards compatibility

DASHBOARD          = OPTIONS['DASHBOARD'].nil? ? '/etc/puppetfactory/dashboard' : OPTIONS['DASHBOARD']
DASHBOARD_INTERVAL = OPTIONS['DASHBOARD_INTERVAL'] || 5 * 60 # test interval in seconds

PE  = OPTIONS['PE'] || true

GITLAB = OPTIONS['GITLAB'] || false

AUTH_INFO = OPTIONS['AUTH_INFO'] || {
  "ca_certificate_path" => "#{CONFDIR}/ssl/ca/ca_crt.pem",
  "certificate_path"    => "#{CONFDIR}/ssl/certs/#{MASTER_HOSTNAME}.pem",
  "private_key_path"    => "#{CONFDIR}/ssl/private_keys/#{MASTER_HOSTNAME}.pem"
}

CLASSIFIER_URL = OPTIONS['CLASSIFIER_URL'] || "http://#{MASTER_HOSTNAME}:4433/classifier-api"

class Puppetfactory < Sinatra::Base
  set :views, File.dirname(__FILE__) + '/../views'
  set :public_folder, File.dirname(__FILE__) + '/../public'

  configure :production, :development do
    enable :logging
    enable :sessions

    # why do I have to do this? This page implies I shouldn't.
    # https://github.com/sinatra/sinatra#logging
    $logger = WEBrick::Log::new(LOGFILE, WEBrick::Log::DEBUG)

    @@current_test = 'summary'
    @@test_running = false

    set :semaphore, Mutex.new
  end

  def initialize(app=nil)
    super(app)
    start_testing(DASHBOARD)
  end

  get '/' do
    @dashboard = DASHBOARD
    erb :index
  end

  get '/login' do
    protected!
    redirect '/'
  end

  get '/home' do
    erb :home
  end

  get '/users' do
    @users   = load_users()
    @current = load_user(session[:username]) if session.include? :username
    erb :users
  end

  get '/users/active/:username' do |username|
    session[:username] = username
    {"status" => "ok"}.to_json
  end

  get '/shell' do
    erb :shell
  end

  get '/dashboard' do
    protected!

    return 'No dashboard configured' unless DASHBOARD

    @current   = @@current_test
    @available = get_available_tests(DASHBOARD)
    @test_data = get_test_data(DASHBOARD)

    return 'No testing data' unless @available and @test_data

    erb :dashboard
  end

  get '/dashboard/details/:user' do |user|
    get_user_test_html(user, @@current_test)
  end

  get '/dashboard/details/:user/:result' do |user, result|
    get_user_test_html(user, result)
  end

  get '/dashboard/update' do
    $logger.info "Triggering dashboard update."

    if update_dashboard_results(DASHBOARD)
      {'status' => 'success'}.to_json
    else
      {'status' => 'fail', 'message' => 'Already running'}.to_json
    end
  end

  get '/dashboard/set/:current' do |current|
    $logger.info "Setting current test to #{current}."
    @@current_test = current

    {'status' => 'success'}.to_json
  end

  get '/new/:username' do |username|
    protected!
    create(username)
  end

  post '/new' do
    confined!
    session[:username] = params[:username]
    create(params[:username], params[:password])
  end

  get '/wetty' do
    redirect "http://#{request.host}:4200"
  end

  get '/port/:port' do |port|
    redirect "http://#{request.host}:#{port}"
  end

  get '/port/:port/' do |port|
    redirect "http://#{request.host}:#{port}"
  end

  # RESTful API endpoints

  # Return details for all users as JSON
  get '/api/users' do
    load_users(true).to_json
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
    def load_users(extended = false)
      # Get the users from the filesystem and look up their info
      users = {}
      Dir.glob('/home/*').each do |path|
        username        = File.basename path
        users[username] = extended ? load_user(username) : basic_user(username)
      end
      users
    end

    def load_user(username)
      # build the basic user object
      user = basic_user(username)
      begin
        # Lookup the container by username and convert to json
        user_container = Docker::Container.get(username).json rescue {}

        user[:container_status] = massage_container_state(user_container['State'])
        user[:node_group_url]   = node_group_url(username)
      rescue => ex
        $logger.error "Error loading user #{username}: #{ex.message}"
        $logger.debug ex.backtrace.join "\n"
      end
      user
    end

    def basic_user(username)
      # build the basic user object
      {
        :username => username,
        :console  => "#{username}@#{USERSUFFIX}",
        :certname => "#{username}.#{USERSUFFIX}",
        :port     => user_port(username),
        :url      => sandbox_url(username),
      }
    end

    def sandbox_url(username)
      port = user_port(username)
      "http://#{request.host}/port/#{port}"
    end

    def user_port(username)
      output = "3" + `id -u #{username}`.chomp
      $? == 0 ? output : nil
    end

    def create(username, password = 'puppetlabs')
      username.downcase!

      begin
        $logger.info add_system_user(username,password)
        $logger.info create_container(username)
        if PE
          $logger.info add_console_user(username,password)
          $logger.info classify(username)
        end

        if GITLAB
          if password.length < 8
            raise "Password must be at least 8 characters"
          end

          # Use default gitlab root password to get session token
          $gitlab_token = JSON.parse(RestClient.post('http://localhost:8888/api/v3/session', {:login => 'root', :password => '5iveL!fe'}))['private_token']

          RestClient.post('http://localhost:8888/api/v3/users',
                          {
                            :email => username + "@puppetfactory.vm",
                            :password => password,
                            :username => username,
                            :name => username,
                            :confirm => false,
                            :private_token => $gitlab_token
                          })
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

        if GITLAB
          # Use default gitlab root password to get session token
          $gitlab_token = JSON.parse(RestClient.post('http://localhost:8888/api/v3/session', {:login => 'root', :password => '5iveL!fe'}))['private_token']
          $users = JSON.parse(RestClient.get('http://localhost:8888/api/v3/users', {"PRIVATE-TOKEN" => $gitlab_token}))
          $users.each do |user|
            if user['username'] == username
              RestClient.delete('http://localhost:8888/api/v3/users' + user['id'] , {"PRIVATE-TOKEN" => $gitlab_token})
            end
          end
        end

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
      output = `adduser #{username} -p '#{crypted}' -G pe-puppet,puppetfactory,#{DOCKER_GROUP} -m 2>&1`

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
        servername = MASTER_HOSTNAME
        @servername = servername
        @username = username
        puppetcode = PUPPETCODE
        map_environments = MAP_ENVIRONMENTS

        templates = "#{File.dirname(__FILE__)}/../templates"

        # Get the uid of the new user and set up URL
        port = user_port(username)

        binds = [
          "/var/yum:/var/yum",
          "/home/#{username}/puppet:#{CONFDIR}",
          "/sys/fs/cgroup:/sys/fs/cgroup:ro"
        ]

        # Create environment dir so that nodegroup works
        environment = "#{ENVIRONMENTS}/#{environment_name(username)}"
        FileUtils.mkdir_p "#{environment}"

        if MAP_ENVIRONMENTS then

          # configure environment
          FileUtils.mkdir_p "#{environment}/manifests"
          FileUtils.mkdir_p "#{environment}/modules"

          File.open("#{environment}/manifests/site.pp", 'w') do |f|
            f.write ERB.new(File.read("#{templates}/site.pp.erb")).result(binding)
          end

          # Copy userprefs module into user environment
          if Dir.exist?("#{CODEDIR}/modules/userprefs") then
            FileUtils.cp_r("#{CODEDIR}/modules/userprefs", "#{environment}/modules/")
          elsif Dir.exist?("#{ENVIRONMENTS}/production/modules/userprefs") then
            FileUtils.cp_r("#{ENVIRONMENTS}/production/modules/userprefs", "#{environment}/modules/")
          else puts "Module userprefs not found in global or production modulepath"
          end

          # make sure the user and pe-puppet can access all the needful
          FileUtils.chown_R(username, 'pe-puppet', environment)
          FileUtils.chmod(0750, environment)
        end

        if MAP_MODULEPATH then
          binds.push("#{environment}:/root/puppetcode")
        end

        # Create shared folder to map and create puppet.conf
        FileUtils.mkdir_p "/home/#{username}/puppet"
        File.open("/home/#{username}/puppet/puppet.conf","w") do |f|
          f.write ERB.new(File.read("#{templates}/puppet.conf.erb")).result(binding)
        end

        # Create container with hostname set for username with port 80 mapped to 3000 + uid
        container = Docker::Container.create(
          "Cmd" => [
            "/usr/lib/systemd/systemd"
          ],
          "Tty" => true,
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
            "Privileged" => false,
            "Binds" => binds,
            "ExtraHosts" => [
              "#{MASTER_HOSTNAME} puppet:#{DOCKER_IP}"
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
        remove_node_group(username)
        remove_certificate(username)
        remove_environment(username)

        container = Docker::Container.get(username)
        output = container.delete(:force => true)
      rescue => e
        raise "Error removing container #{username}: #{e.message}"
      end

      "Container #{username} removed"
    end

    def massage_container_state(state)
      return {'Description' => 'No container.'} if state.nil?

      if state['OOMKilled']
        state['Description'] = 'Halted because host machine is out of memory.'
      elsif state['Restarting']
        state['Description'] = 'Container is restarting.'
      elsif state['Paused']
        state['Description'] = 'Container is paused.'
      elsif state['Running']
        state['Description'] = "Running since #{Time.parse(state['StartedAt']).strftime("%b %d at %I:%M%p")}"
      else
        state['Description'] = 'Halted.'
      end
      state
    end

    def init_scripts(username)
      templates = "#{File.dirname(__FILE__)}/../templates"
      service_file = "/etc/systemd/system/docker-#{username}.service"
      File.open(service_file,"w") do |f|
        f.write ERB.new(File.read("#{templates}/init_scripts.erb")).result(binding)
      end
      File.chmod(0644, service_file)
      `chkconfig docker-#{username} on`
    end

    def remove_init_scripts(username)
      `chkconfig docker-#{username} off`
      FileUtils.rm(service_file)
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

    def remove_certificate(username)
      begin
        %x{puppet cert clean #{username}.puppetlabs.vm}
      rescue => e
        raise "Error cleaning certificate #{username}.puppetlabs.vm: #{e.message}"
      end

      "Certificate #{username}.puppetlabs.vm removed"
    end

    def remove_environment(username)
      begin
        environment_path = "#{CODEDIR}/environments/#{username}"
        %x{rm -rf #{environment_path}}
        if File.exist?("#{environment_path}_production") then
          %x{rm -rf #{environment_path}_production}
        end
      rescue => e
        raise "Error removing environment #{username}: #{e.message}"
      end

      "Environment #{username} removed"
    end

    def node_group_id(username)
      puppetclassify = PuppetClassify.new(CLASSIFIER_URL, AUTH_INFO)
      certname = "#{username}.#{USERSUFFIX}"

      puppetclassify.groups.get_group_id(certname)
    end

    def node_group_url(username)
      nodegroup = node_group_id(username)
      "https://#{request.host}/#/node_groups/groups/#{nodegroup}" if nodegroup
    end

    def node_group_status(username)
      ! node_group_id(username).nil?
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


    def start_testing(path)
      Thread.new do
        loop do
          $logger.info "Updating dashboard after #{DASHBOARD_INTERVAL} seconds."
          update_dashboard_results(path)
          sleep(DASHBOARD_INTERVAL)
        end
      end
    end

    def update_dashboard_results(path)
      return false if @@test_running
      @@test_running = true

      Dir.chdir(path) do
        case @@current_test
        when 'all', 'summary'
          `rake generate`
        else
          `rake generate current_test=#{@@current_test}`
        end
      end

      @@test_running = false
      true
    end

    def get_available_tests(path)
      Dir.chdir(path) { `rake list`.split } rescue []
    end

    def set_current_test(current)
      @current_test = current
    end

    def get_test_data(path)
      JSON.parse(File.read("#{path}/output/summary.json")) rescue {}
    end

    def get_user_test_html(user, result)
      begin
      if result == 'summary'
        File.read("#{DASHBOARD}/output/html/#{user}.html")
      else
        File.read("#{DASHBOARD}/output/html/#{result}/#{user}.html")
      end
      rescue Errno::ENOENT
        'No results found'
      end
    end

    def test_completion(data)
      total  = data['example_count'] rescue 0
      failed = data['failure_count'] rescue 0
      passed = total - failed
      percent = passed.to_f / total * 100.0 rescue 0

      [total, passed, percent]
    end

    def approximate_time_difference(timestamp)
      return 'never' if timestamp.nil?

      start = Time.parse(timestamp)
      delta = (Time.now - start)

      if delta > 60
        # This grossity is rounding to the nearest whole minute
        mins = ((delta / 600).round(1)*10).to_i
        "about #{mins} minutes ago"
      else
        "#{delta.to_i} seconds ago"
      end
    end

    # Basic auth boilerplate
    def protected!
      unless authorized?
        response['WWW-Authenticate'] = %(Basic realm="Restricted Area")
        throw(:halt, [401, "Not authorized\n"])
      end
    end

    def confined!
      unless params[:session] == SESSION
        throw(:halt, [403, "Only classroom members are allowed to create accounts!\n"])
      end
    end

    def privileged?
      session[:privileges] == 'admin'
    end

    def authorized?
      @auth ||=  Rack::Auth::Basic::Request.new(request.env)

      if @auth.provided? && @auth.basic? && @auth.credentials == [USER, PASSWORD]
        session[:privileges] = 'admin'
        true
      else
        session.delete :privileges
        false
      end
    end

  end
end
