require 'json'
require 'fileutils'
require 'puppetfactory'

class Puppetfactory::Plugins::Gitea < Puppetfactory::Plugins

  def initialize(options)
    super(options)

    @suffix         = options[:usersuffix]
    @gitea_path     = options[:gitea_path] || '/home/git/go/bin/gitea'
    @admin_username = options[:gitea_admin_username] || 'root'
    @admin_password = options[:gitea_admin_password] || 'puppetlabs'
    @gitea_port     = options[:gitea_port] || '3000'

    begin
      `curl -su "#{@admin_username}:#{@admin_password}" --data 'clone_addr=https://github.com/puppetlabs-education/classroom-control-vf.git&uid=1&repo_name=classroom-control-vf' http://localhost:#{@gitea_port}/api/v1/repos/migrate`
      FileUtils::mkdir_p '/var/cache/puppetfactory/gitea'
      Dir.chdir('/var/cache/puppetfactory/gitea') do
        `git clone --depth 1 http://#{@admin_username}:#{@admin_password}@localhost:#{@gitea_port}/#{@admin_username}/classroom-control-vf.git`
      end
    rescue => e
      $logger.error "Error migrating repository: #{e.message}"
      return false
    end

  end

  def add_collaborator(owner, repo, username, permission)
    `curl -su "#{@admin_username}:#{@admin_password}" -X PUT -H "Content-Type: application/json" -d '{"permissions":"#{permission}"}' http://localhost:#{@gitea_port}/api/v1/repos/#{owner}/#{repo}/collaborators/#{username}`
  end

  def make_branch(username)
    Dir.chdir('/var/cache/puppetfactory/gitea/classroom-control-vf') do
      `git checkout -b #{username} && git push origin #{username}`
    end
  end

  def create(username, password)
    begin
      if password.length < 8
        raise "Password must be at least 8 characters"
      end
      `su git -c "cd && #{@gitea_path} admin create-user --name #{username} --password #{password} --email #{username}.#{@suffix}"`
      add_collaborator(@admin_username, 'classroom-control-vf', username, 'write')
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
      $logger.info "Removed GitLab user #{username}."
    rescue => e
      $logger.error "Error removing GitLab user #{username}: #{e.message}"
      return false
    end

    true
  end

end
