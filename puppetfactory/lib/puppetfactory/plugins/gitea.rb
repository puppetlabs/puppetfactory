require 'json'
require 'fileutils'
require 'puppetfactory'

class Puppetfactory::Plugins::Gitea < Puppetfactory::Plugins

  def initialize(options)
    super(options)

    @suffix         = options[:usersuffix]
    @controlrepo    = options[:controlrepo]
    @reponame       = File.basename(@controlrepo, '.git')
    @gitea_path     = options[:gitea_path] || '/home/git/go/bin/gitea'
    @admin_username = options[:gitea_admin_username] || 'root'
    @admin_password = options[:gitea_admin_password] || 'puppetlabs'
    @gitea_port     = options[:gitea_port] || '3000'

    @cache_dir = '/var/cache/puppetfactory/gitea'

    if (!File.directory?("#{@cache_dir}/#{@reponame}"))
      $logger.info "Migrating repository #{@reponame}"
      begin
        `curl -su "#{@admin_username}:#{@admin_password}" --data "clone_addr=https://github.com/puppetlabs-education/#{@controlrepo}&uid=1&repo_name=#{@reponame}" http://localhost:#{@gitea_port}/api/v1/repos/migrate`
        FileUtils::mkdir_p @cache_dir
        Dir.chdir(@cache_dir) do
          `git clone --depth 1 http://#{@admin_username}:#{@admin_password}@localhost:#{@gitea_port}/#{@admin_username}/#{@controlrepo}`
        end
      rescue => e
        $logger.error "Error migrating repository: #{e.message}"
        return false
      end
    end
  end

  def add_collaborator(owner, repo, username, permission)
    `curl -su "#{@admin_username}:#{@admin_password}" -X PUT -H "Content-Type: application/json" -d '{"permissions":"#{permission}"}' http://localhost:#{@gitea_port}/api/v1/repos/#{owner}/#{repo}/collaborators/#{username}`
  end

  def make_branch(username)
    Dir.chdir("#{@cache_dir}/#{@reponame}") do
      `git checkout -b #{username} && git push origin #{username}`
    end
  end

  def create(username, password)
    begin
      if password.length < 8
        raise "Password must be at least 8 characters"
      end
      `su git -c "cd && #{@gitea_path} admin create-user --name #{username} --password #{password} --email #{username}@#{@suffix}"`
      add_collaborator(@admin_username, @reponame, username, 'write')
      make_branch(username)
      $logger.info "Created Gitea user #{username}."
    rescue => e
      $logger.error "Error creating Gitea user #{username}: #{e.message}"
      return false
    end

    true
  end

  def delete(username)
    begin
      `curl -su "#{@admin_username}:#{@admin_password}" -X "DELETE" http://localhost:#{@gitea_port}/api/v1/admin/users/#{username}`
      $logger.info "Removed Gitea user #{username}."
    rescue => e
      $logger.error "Error removing Gitea user #{username}: #{e.message}"
      return false
    end

    true
  end

end
