require 'json'
require 'fileutils'
require 'restclient'
require 'puppetfactory'

class Puppetfactory::Plugins::Gitea < Puppetfactory::Plugins

  def initialize(options)
    super(options)

    @cache_dir      = '/var/cache/puppetfactory/gitea'
    @lockfile       = '/var/cache/puppetfactory/gitea.lock'
    @suffix         = options[:usersuffix]
    @controlrepo    = options[:controlrepo]
    @reponame       = File.basename(@controlrepo, '.git')
    @repopath       = "#{@cache_dir}/#{@reponame}"
    @gitea_upstream = options[:gitea_upstream]       || "https://github.com/puppetlabs-education/#{@controlrepo}"
    @gitea_cmd      = options[:gitea_cmd]            || '/home/git/go/bin/gitea'
    @admin_username = options[:gitea_admin_username] || 'root'
    @admin_password = options[:gitea_admin_password] || 'puppetlabs'
    @gitea_port     = options[:gitea_port]           || '3000'
    @gitea_user     = options[:gitea_user]           || 'git'
    @gitea_homedir  = Dir.home(@gitea_user)

    # the rest of this method is for the big boys only
    return unless Process.euid == 0

    # gitea will scream if the admin's .ssh directory doesn't exist
    FileUtils.mkdir_p(File.expand_path("~#{@admin_username}/.ssh"))

    migrate_repo! unless File.directory?(@cache_dir)
  end

  def create(username, password)
    begin
      # since we're changing directories, none of this can be done concurrently; lock it all.
      #
      # TODO: consider forking worker processes so that CWD doesn't leak between threads.
      File.open(@lockfile, 'w') do |file|
        file.flock(File::LOCK_EX)

        make_user(username, password)
        $logger.debug "Created Gitea user #{username}."
        make_branch(username)
        $logger.debug "Created Gitea branch #{username}."
        add_collaborator(@admin_username, @reponame, username, 'write')
        $logger.info "Created Gitea collaborator #{username}."
      end
    rescue => e
      $logger.error "Error configuring Gitea for #{username}: #{e.message}"
      $logger.error e.backtrace.join("\n")
      return false
    end

    true
  end

  def delete(username)
    begin
      remove_user(username)
      $logger.info "Removed Gitea user #{username}."
    rescue => e
      $logger.error "Error removing Gitea user #{username}: #{e.message}"
      return false
    end

    true
  end

  private
    def migrate_repo!
      FileUtils::mkdir_p @cache_dir
      $logger.info "Migrating repository #{@reponame}"
      begin
        RestClient.post("http://#{@admin_username}:#{@admin_password}@localhost:#{@gitea_port}/api/v1/repos/migrate", {
                          'clone_addr' => @gitea_upstream,
                          'uid'        => 1,
                          'repo_name'  => @reponame,
                       })

        # make sure the server has time to finish cloning from GitHub before cloning
        sleep 5

        Dir.chdir(@cache_dir) do
          repo_uri = "http://#{@admin_username}:#{@admin_password}@localhost:#{@gitea_port}/#{@admin_username}/#{@controlrepo}"
          output, status = Open3.capture2e('git', 'clone', '--depth', '1', repo_uri)
          raise output unless status.success?
        end

      rescue => e
        $logger.error "Error migrating repository: #{e.message}"
        $logger.error e.backtrace.join("\n")
        return false
      end
    end

    def make_user(username, password)
      Dir.chdir(@gitea_homedir) do
        uid = Etc.getpwnam(@gitea_user).uid
        pid = Process.fork do
          ENV['USER']  = @gitea_user
          Process.uid  = uid
          Process.euid = uid

          output, status = Open3.capture2e(@gitea_cmd, 'admin', 'create-user',
                                            '--name',     username,
                                            '--password', password,
                                            '--email',    "#{username}@#{@suffix}")

          $logger.error output unless status.success?
          exit status.exitstatus
        end

        pid, status = Process.wait2(pid)
        raise "Error creating Gitea user #{username}" unless status.success?
      end
    end

    def add_collaborator(owner, repo, username, permission)
      repo_uri = "http://#{@admin_username}:#{@admin_password}@localhost:#{@gitea_port}/api/v1/repos/#{owner}/#{repo}/collaborators/#{username}"
      RestClient.put(repo_uri, {'permissions' => permission}.to_json)
    end

    def make_branch(username)
      Dir.chdir(@repopath) do
        # use --force in case the branch already exists
        output, status = Open3.capture2e('git', 'branch', '--force', username)
        raise output unless status.success?

        output, status = Open3.capture2e('git', 'push', 'origin', username)
        raise output unless status.success?
      end
    end

    def remove_user(username)
      RestClient.delete("http://#{@admin_username}:#{@admin_password}@localhost:#{@gitea_port}/api/v1/admin/users/#{username}")
    end

end
