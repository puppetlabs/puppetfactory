require 'puppetfactory'

class Puppetfactory::Plugins::R10k < Puppetfactory::Plugins

  def initialize(options)
    super(options)

    @gitserver    = options[:gitserver]
    @repomodel    = options[:repomodel]
    @controlrepo  = options[:controlrepo]
    @environments = options[:environments]
    @r10k_config  = '/etc/puppetlabs/r10k/r10k.yaml'
    @pattern      = "#{@gitserver}/%s/#{@controlrepo}"

    # the rest of this method is for the big boys only
    return unless Process.euid == 0

    # in case this is the first run and it doesn't exist yet
    unless File.exist? @r10k_config
      File.open(@r10k_config, 'w') { |f| f.write({'sources' => {}}.to_yaml) }
    end
  end

  def create(username, password)
    begin
      environment = "#{@environments}/#{Puppetfactory::Helpers.environment_name(username)}"
      FileUtils.mkdir_p environment
      FileUtils.chown_R(username, 'pe-puppet', environment)
      FileUtils.chmod(0750, environment)

      # We don't need to add sources unless we're using a repo per student.
      if @repomodel == :peruser
        File.open(@r10k_config) do |file|
          # make sure we don't have any concurrency issues
          file.flock(File::LOCK_EX)

          r10k = YAML.load_file(@r10k_config)
          r10k['sources'][username] = {
            'remote'  => sprintf(@pattern, username),
            'basedir' => @environments,
            'prefix'  => true,
          }

          # Ruby 1.8.7, why don't you just go away now
          File.open(@r10k_config, 'w') { |f| f.write(r10k.to_yaml) }
          $logger.info "Created r10k source for #{username}"
        end
      end
    rescue => e
      $logger.error "Cannot create r10k source for #{username}"
      $logger.error e.backtrace
      return false
    end

    true
  end

  def delete(username)
    return unless @repomodel == :peruser

    begin
      environment = "#{@environments}/#{Puppetfactory::Helpers.environment_name(username)}"
      FileUtils.rm_rf environment

      # also delete any prefixed environments. Is this even a good idea?
      FileUtils.rm_rf "#{@environments}/#{username}_*" if @repomodel == :peruser

      File.open(@r10k_config) do |file|
        # make sure we don't have any concurrency issues
        file.flock(File::LOCK_EX)

        r10k = YAML.load_file(@r10k_config)
        r10k['sources'].delete username

        # Ruby 1.8.7, why don't you just go away now
        File.open(@r10k_config, 'w') { |f| f.write(r10k.to_yaml) }
        $logger.info "Removed r10k source for #{username}"
      end
    rescue => e
      $logger.error "Cannot remove r10k source for #{username}"
      $logger.error e.backtrace
      return false
    end

    true
  end

  def deploy(username)
    environment = Puppetfactory::Helpers.environment_name(username)

    output, status = Open3.capture2e('r10k', 'deploy', 'environment', environment)
    unless status.success?
      $logger.error "Failed to deploy environment #{environment} for #{username}"
      $logger.error output
      return false
    end

    $logger.info "Deployed environment #{environment} for #{username}"
    true
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

    true
  end

end
