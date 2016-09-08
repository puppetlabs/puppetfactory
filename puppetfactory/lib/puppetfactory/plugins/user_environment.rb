require 'json'
require 'puppetfactory'

class Puppetfactory::Plugins::UserEnvironment < Puppetfactory::Plugins

  def initialize(options)
    super(options)

    @codedir      = options[:codedir]
    @confdir      = options[:confdir]
    @puppetcode   = options[:puppetcode]
    @templatedir  = options[:templatedir]
    @environments = options[:environments]
    @modulepath   = options[:modulepath]
    @repomodel    = options[:repomodel]
  end

  def create(username, password)
    environment = "#{@environments}/#{Puppetfactory::Helpers.environment_name(username)}"

    begin
      # configure environment
      FileUtils.mkdir_p "#{environment}/manifests"
      FileUtils.mkdir_p "#{environment}/modules"

      File.open("#{environment}/manifests/site.pp", 'w') do |f|
        f.write ERB.new(File.read("#{@templatedir}/site.pp.erb")).result(binding)
      end

      # Copy userprefs module into user environment
      if Dir.exist?("#{@codedir}/modules/userprefs") then
        FileUtils.cp_r("#{@codedir}/modules/userprefs", "#{environment}/modules/")
      elsif Dir.exist?("#{@environments}/production/modules/userprefs") then
        FileUtils.cp_r("#{@environments}/production/modules/userprefs", "#{environment}/modules/")
      else
        $logger.warn "Module userprefs not found in global or production modulepath"
      end

      # make sure the user and pe-puppet can access all the needful
      FileUtils.chown_R(env_user, 'pe-puppet', environment)
      FileUtils.chmod(0750, environment)

    rescue => e
      $logger.error "Error creating user environment for #{username}"
      $logger.error e.message
      return false
    end

    true
  end

  def delete(username)
    environment = "#{@environments}/#{Puppetfactory::Helpers.environment_name(username)}"
    FileUtils.rm_rf environment

    # also delete any prefixed environments. Is this even a good idea?
    FileUtils.rm_rf "#{@environments}/#{username}_*" if @repomodel == :peruser
  end

  def deploy(username)
    create(username, nil)
  end

  def redeploy(username)
    begin
      if username == 'production'
        raise "Can't redeploy production environment"
      end
      delete(username)
      deploy(username)

    rescue => e
      raise "Error redeploying environment #{username}: #{e.message}"
    end
  end

end
