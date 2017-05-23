require 'octokit'
require 'puppetfactory'

class Puppetfactory::Plugins::Github < Puppetfactory::Plugins

  def initialize(options)
    super(options)

    @gitserver   = options[:gitserver]
    @gituser     = options[:gituser]
    @controlrepo = options[:controlrepo]
    @repomodel   = options[:repomodel]
    @githubtoken = options[:githubtoken]

    # chomp so we can support repo names with or without the .git
    @controlrepo.chomp!('.git')

    if @githubtoken
      @client = Octokit::Client.new(:access_token => @githubtoken)
      @client.user.login
    else
      @client = Octokit::Client.new()
    end
  end

  def create(username, password)
    # can only do anything on our own repo, and only if we're authorized!
    return true unless @githubtoken and @repomodel == :single

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
    return true unless @githubtoken and @repomodel == :single

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
      repo = "#{@gituser}/#{@controlrepo}"
      url  = "#{@gitserver}/#{@gituser}/#{@controlrepo}/tree/#{username}"
    else
      repo = "#{@username}/#{@controlrepo}"
      url  = "#{@gitserver}/#{username}/#{@controlrepo}"
    end

    userinfo = {
      :username     => username,
      :controlrepo  => url,
    }
    userinfo[:latestcommit] = latest_commit(repo, username) if extended
    userinfo
  end

  private
  def latest_commit(repo, username)
    begin
      commit = @client.commits(repo, :author => username).first
      return if commit.nil?

      {
        :url     => commit[:html_url],
        :message => commit[:commit][:message].trim(62),
        :time    => Puppetfactory::Helpers.approximate_time_difference(commit[:commit][:author][:date]),
      }
    rescue => e
      $logger.error "Cannot get commits for #{repo}."
      $logger.error e.message
    end
  end
end
