require 'json'
require 'puppetfactory'

class Puppetfactory::Plugins::ShellUser < Puppetfactory::Plugins

  def initialize(options)
    super(options)

    @weight      = 1
    @usersuffix  = options[:usersuffix]
    @puppet      = options[:puppet]
    @master      = options[:master]
    @templatedir = options[:templatedir]
    @shell       = `which pfsh`.chomp

    # don't like this coupling, but I don't see a better way
    @groups = ['pe-puppet','puppetfactory']
    @groups << 'docker' if options[:plugins].include? :Docker
  end

  def create(username, password)
    unless username =~ /^[a-z_][a-z0-9_]{2,30}$/
      $logger.error "Invalid username. '#{username}' does not match regex /^[a-z_][a-z0-9_]{2,30}$/"
      raise "Invalid username #{username}."
    end

    crypted = password.crypt("$5$a1")
    output, status = Open3.capture2e('adduser', username, '-p', crypted, '-G', @groups.join(','), '--shell', @shell)
    unless status.success?
      $logger.error "Could not create system user #{username}: #{output}"
      raise "Could not create system user #{username}"
    end

    # Create shared folder to map and create puppet.conf
    FileUtils.mkdir_p "/home/#{username}/puppet"
    File.open("/home/#{username}/puppet/puppet.conf","w") do |f|
      f.write ERB.new(File.read("#{@templatedir}/puppet.conf.erb")).result(binding)
    end

    $logger.info "System user #{username} created successfully"
    true
  end

  def delete(username)
    output, status = Open3.capture2e('userdel', '-fr', username)
    if status.success?
      $logger.info "System user #{username} removed successfully"
      return true
    else
      $logger.warn "Could not remove system user #{username}: #{output}"
      return false
    end
  end

  def users
    usernames = Dir.glob('/home/*').map { |path| File.basename path }
    usernames.reject { |username| ['centos', 'git', 'showoff', 'training', 'vagrant'].include? username }
  end

  def userinfo(username, extended = false)
    # build the basic user object, can be added to by other plugins
    {
      :username => username,
      :console  => "#{username}@#{@usersuffix}",
      :certname => "#{username}.#{@usersuffix}",
    }
  end

end
