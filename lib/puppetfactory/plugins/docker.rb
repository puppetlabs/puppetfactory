require 'erb'
require 'time'
require 'docker'
require 'etc'
require 'json'
require 'puppetfactory'

class Puppetfactory::Plugins::Docker < Puppetfactory::Plugins

  def initialize(options)
    super(options)

    @weight = 5

    @confdir      = options[:confdir]
    @stagedir     = options[:stagedir]
    @environments = "#{@stagedir}/environments"
    @puppetcode   = options[:puppetcode]
    @master       = options[:master]
    @usersuffix   = options[:usersuffix]
    @modulepath   = options[:modulepath]
    @templatedir  = options[:templatedir]
    @container    = options[:container_name] || 'centosagent'
    @group        = options[:docker_group]   || 'docker'
    @docker_ip    = options[:docker_ip]      || `facter ipaddress_docker0`.strip
    @privileged   = options[:privileged]     || false
  end

  def create(username, password)
    begin
      environment = "#{@environments}/#{Puppetfactory::Helpers.environment_name(username)}"
      binds = [
        "/var/yum:/var/yum",
        "/var/cache/rubygems:/var/cache/rubygems",
        "/var/cache/yum:/var/cache/yum",
        "/etc/pki/rpm-gpg:/etc/pki/rpm-gpg",
#        "/etc/yum.repos.d:/etc/yum.repos.d", # we can't share this because of pe_repo.repo
#        "/opt/puppetlabs/server:/opt/puppetlabs/server",
        "/home/#{username}/puppet:#{@confdir}",
        "/sys/fs/cgroup:/sys/fs/cgroup:ro"
      ]

      case @modulepath
      when :readonly
        binds.push("#{environment}:#{@puppetcode}:ro")
      when :readwrite
        binds.push("#{environment}:#{@puppetcode}")
      when :none
        #pass
      else
        raise "Uknown modulepath setting (#{@modulepath})"
      end

      container = ::Docker::Container.create(
        "Cmd" => [
          "/usr/lib/systemd/systemd"
        ],
        "Tty" => true,
        "Domainname" => @usersuffix,
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
        "Image" => "#{@container}",
        "HostConfig" => {
          "Privileged" => @privileged,
          "SecurityOpt" => [
            "seccomp=unconfined"
          ],
          "Tmpfs" => {
            "/run" => "",
            "/tmp" => ""
          },
          "Binds" => binds,
          "ExtraHosts" => [
            "#{@master} puppet:#{@docker_ip}"
          ],
          "PortBindings" => {
            "80/tcp" => [
              {
                "HostPort" => "#{user_port(username)}"
              }
            ]
          },
        },
        "Name" => "#{username}"
      )

      container.rename(username) # Set container name so we can identify it
      init_scripts(username)     # Create init scripts so container restarts on boot
      container.start

    rescue => e
      # fatal error, so we stop execution here
      raise "Error creating container #{username}: #{e.message}"
    end

    $logger.info "Container #{username} created"
    true
  end

  def delete(username)
    begin
      remove_init_scripts(username)

      container = ::Docker::Container.get(username)
      output = container.delete(:force => true)
    rescue => e
      $logger.warn "Error removing container #{username}: #{e.message}"
      return false
    end

    $logger.info "Container #{username} removed"
    true
  end

  def repair(username)
    begin
      container = ::Docker::Container.get(username)
      container.delete(:force => true)

      create(username, nil)
    rescue => e
      raise "Error reparing container #{username}: #{e.message}"
    end

    $logger.info "Container #{username} repaired"
    true
  end

  def userinfo(username, extended = false)
    user = {
      :username => username,
      :port     => user_port(username),
      :url      => sandbox_url(username),
    }

    if extended
      user_container = ::Docker::Container.get(username).json rescue {}
      user[:container_status] = massage_container_state(user_container['State'])
    end

    user
  end

  def login
    require 'etc'
    username = Etc.getpwuid(Process.euid).name
    exec("docker exec -it #{username} su -")
  end

  private
  def sandbox_url(username)
    "/port/#{user_port(username)}"
  end

  # TODO: We need a better way of doing this, since we're not guaranteed to always have system users.
  #       See plugins/shell_user.rb for the other side of this coupling.
  def user_port(username)
    Etc.getpwnam(username).uid + 3000 rescue nil
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
    service_file = "/etc/systemd/system/docker-#{username}.service"
    File.open(service_file,"w") do |f|
      f.write ERB.new(File.read("#{@templatedir}/init_scripts.erb")).result(binding)
    end
    File.chmod(0644, service_file)
    system('chkconfig', "docker-#{username}", 'on')

    $logger.info "Init scripts created and enabled for container #{username}"
  end

  def remove_init_scripts(username)
    service_file = "/etc/systemd/system/docker-#{username}.service"
    system('chkconfig', "docker-#{username}", 'off')
    FileUtils.rm(service_file) if File.exist? service_file

    $logger.info "Init scripts for container #{username} removed"
  end

end
