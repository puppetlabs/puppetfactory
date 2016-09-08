require 'puppetfactory'
require 'hocon'
require 'hocon/parser/config_document_factory'
require 'hocon/config_value_factory'

class Puppetfactory::Plugins::CodeManager < Puppetfactory::Plugins

  def initialize(options)
    super(options)

    @puppet       = options[:puppet]
    @gitserver    = options[:gitserver]
    @repomodel    = options[:repomodel]
    @controlrepo  = options[:controlrepo]
    @environments = options[:environments]
    @sources      = '/etc/puppetlabs/puppet/hieradata/sources.yaml' # we can hardcode these assumptions
    @meep         = '/etc/puppetlabs/enterprise/conf.d/common.conf' # because CM is PE only.
    @pattern      = "#{@gitserver}/%s/#{@controlrepo}"

    # the rest of this method is for the big boys only
    return unless Process.euid == 0

    # in case this is the first run and these doesn't exist yet
    unless File.exist? @sources
      FileUtils.mkdir_p File.dirname @sources
      File.open(@sources, 'w') { |f| f.write( { 'puppet_enterprise::master::code_manager::sources' => {} }.to_yaml) }
    end
    File.open(@meep, 'w') { |f| f.write('') } unless File.exist? @meep

    if options[:codedir]
      # ensure sane file permissions
      FileUtils.chown_R('pe-puppet', 'pe-puppet', options[:codedir])
      FileUtils.chmod(0755, options[:codedir])
    end
  end

  def create(username, password)
    begin
      environment = "#{@environments}/#{Puppetfactory::Helpers.environment_name(username)}"
      FileUtils.mkdir_p environment
      FileUtils.chown_R(username, 'pe-puppet', environment)
      FileUtils.chmod(0750, environment)

      File.open(@sources) do |file|
        # make sure we don't have any concurrency issues
        file.flock(File::LOCK_EX)

        # We need to duplicate the sources list in the MEEP config for recovery options
        # I'd like to add it to code-manager.conf too and avoid the delay of running
        # puppet, but that's a race condition that we cannot accept.
        File.open(@meep) do |anotherfile|
          anotherfile.flock(File::LOCK_EX)

          source = {
            'remote'  => sprintf(@pattern, username),
            'prefix'  => (@repomodel == :peruser),
          }

          sources = YAML.load_file(@sources)
          meep    = Hocon::Parser::ConfigDocumentFactory.parse_file(@meep)

          sources['puppet_enterprise::master::code_manager::sources'][username] = source
          meep = meep.set_config_value(
                      "\"puppet_enterprise::master::code_manager::sources\".#{username}",
                      Hocon::ConfigValueFactory.from_any_ref(source)
                    )

          # Ruby 1.8.7, why don't you just go away now
          File.open(@sources, 'w') { |f| f.write(sources.to_yaml) }
          File.open(@meep, 'w')    { |f| f.write(meep.render)     }
          $logger.info "Created Code Manager source for #{username}"
        end
      end
    rescue => e
      $logger.error "Cannot create Code Manager source for #{username}"
      $logger.error e.backtrace
      return false
    end

    true
  end

  def delete(username)
    begin
      environment = "#{@environments}/#{Puppetfactory::Helpers.environment_name(username)}"
      FileUtils.rm_rf environment

      # also delete any prefixed environments. Is this even a good idea?
      FileUtils.rm_rf "#{@environments}/#{username}_*" if @repomodel == :peruser

      File.open(@sources) do |file|
        # make sure we don't have any concurrency issues
        file.flock(File::LOCK_EX)

        # We need to duplicate the sources list in the MEEP config for recovery options
        # I'd like to add it to code-manager.conf too and avoid the delay of running
        # puppet, but that's a race condition that we cannot accept.
        File.open(@meep) do |anotherfile|
          anotherfile.flock(File::LOCK_EX)

          source = {
            'remote'  => sprintf(@pattern, username),
            'prefix'  => (@repomodel == :peruser),
          }

          sources = YAML.load_file(@sources)
          sources['puppet_enterprise::master::code_manager::sources'].delete username rescue nil

          meep = Hocon::Parser::ConfigDocumentFactory.parse_file(@meep)
          meep = meep.remove_value("\"puppet_enterprise::master::code_manager::sources\".#{username}")

          # Ruby 1.8.7, why don't you just go away now
          File.open(@sources, 'w') { |f| f.write(sources.to_yaml) }
          File.open(@meep, 'w')    { |f| f.write(meep.render)     }
          $logger.info "Removed Code Manager source for #{username}"
        end
      end
    rescue => e
      $logger.error "Cannot remove Code Manager source for #{username}"
      $logger.error e.backtrace
      return false
    end

    true
  end

  def deploy(username)
    environment = Puppetfactory::Helpers.environment_name(username)

    output, status = Open3.capture2e(@puppet, 'code', 'deploy', environment, '--wait')
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
