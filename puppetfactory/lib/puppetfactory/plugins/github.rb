require 'octokit'
require 'puppetfactory'

class Puppetfactory::Plugins::Github < Puppetfactory::Plugins

  def initialize(options)
    super(options)

    @gitserver   = options[:gitserver]
    @gituser     = options[:gituser]
    @controlrepo = options[:controlrepo]
    @repomodel   = options[:repomodel]

    # chomp so we can support repo names with or without the .git
    @controlrepo.chomp!('.git')

    if options[:githubtoken]
      @client = Octokit::Client.new(:access_token => options[:githubtoken])
      @client.user.login
    end
  end

  def create(username, password)
    # can only do anything on our own repo, and only if we're authorized!
    return true unless @client and @repomodel == :single

    begin
      # can only do anything on our own repo!
      repo = "#{@gituser}/#{@controlrepo}"
      sha  = @client.branches(repo).select { |branch| branch[:name] == 'production' }.first[:commit][:sha]
      @client.create_ref(repo, "heads/#{username}", sha)
      $logger.info "Created Github user branch for #{username}"

      @client.add_collaborator(repo, username)
      $logger.info "Added #{username} as a collaborator to #{repo}."

    rescue => e
      $logger.error "Error creating Github user branch for #{username}"
      $logger.error e.message
      return false
    end

    true
  end

  def delete(username)
    # can only do anything on our own repo, and only if we're authorized!
    return true unless @client and @repomodel == :single

    begin
      @client.delete_branch("#{@gituser}/#{@controlrepo}", username)
      $logger.info "Deleted Github user branch for #{username}"

      @client.remove_collaborator(repo, username)
      $logger.info "Removed #{username} as a collaborator on #{repo}."

    rescue => e
      $logger.error "Error deleting Github user branch for #{username}"
      $logger.error e.message
      return false
    end

    true
  end

  def userinfo(username, extended = false)
    if @repomodel == :single
      controlrepo = "#{@gitserver}/#{@gituser}/#{@controlrepo}/tree/#{username}"
    else
      controlrepo = "#{@gitserver}/#{username}/#{@controlrepo}"
    end
    {
      :username    => username,
      :controlrepo => controlrepo,
    }
  end

end
