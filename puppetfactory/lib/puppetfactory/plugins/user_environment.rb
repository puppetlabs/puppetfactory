require 'json'
require 'restclient'
require 'puppetfactory'

class Puppetfactory::Plugins::UserEnvironment < Puppetfactory::Plugins

  def initialize(options)
    super(options)

    @master       = options[:master]
    @confdir      = options[:confdir]
    @codedir      = options[:codedir]
    @stagedir     = options[:stagedir]
    @puppetcode   = options[:puppetcode]
    @templatedir  = options[:templatedir]
    @environments = options[:environments]
    @repomodel    = options[:repomodel]
    @codestage   = "#{@stagedir}/environments"
  end

  def create(username, password)
    environment = "#{@codestage}/#{Puppetfactory::Helpers.environment_name(username)}"

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
      FileUtils.chown_R(username, 'pe-puppet', environment)
      FileUtils.chmod_R(0750, environment)

      deploy(username)

    rescue => e
      $logger.error "Error creating user environment for #{username}"
      $logger.error e.message
      return false
    end

    true
  end

  def delete(username)
    FileUtils.rm_rf "#{@codestage}/#{Puppetfactory::Helpers.environment_name(username)}"
    FileUtils.rm_rf "#{@environments}/#{Puppetfactory::Helpers.environment_name(username)}"
  end

  def deploy(username)
    environment = Puppetfactory::Helpers.environment_name(username)

    begin
      FileUtils.cp_r("#{@codestage}/#{environment}/*", "#{@environments}/#{environment}/")
      FileUtils.chown_R('pe-puppet', 'pe-puppet', "#{@environments}/#{environment}")

      RestClient::Resource.new(
        "https://#{@master}:8140/puppet-admin-api/v1/environment-cache?environment=#{environment}",
        :ssl_client_cert  =>  OpenSSL::X509::Certificate.new(File.read("#{@confdir}/ssl/certs/#{@master}.pem")),
        :ssl_client_key   =>  OpenSSL::PKey::RSA.new(File.read("#{@confdir}/ssl/private_keys/#{@master}.pem")),
        :ssl_ca_file      =>  "#{@confdir}/ssl/ca/ca_crt.pem",
        :verify_ssl       =>  OpenSSL::SSL::VERIFY_PEER
      ).delete
    rescue => e
      $logger.error "Deploying environment #{environment} failed: #{e.message}"
      $logger.debug e.backtrace
      raise "Error deploying environment #{environment}."
    end
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
