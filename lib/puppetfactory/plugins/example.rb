require 'puppetfactory'

# inherit from Puppetfactory::Plugins
class Puppetfactory::Plugins::Example < Puppetfactory::Plugins
  attr_reader :weight

  def initialize(options)
    super(options) # call the superclass to initialize it

    @weight  = 1
    @example = options[:example] || '/tmp/example'
  end

  # include one or more of the following methods. Any method you implement
  # will be called when the corresponding task is invoked.

  def create(username, password)
    $logger.info "User #{username} created."

    # Log an error with $logger.error
    # fail user creation with a fatal error by raising an exception

    # return true if our action succeeded
    true
  end

  def delete(username)
    $logger.info "User #{username} deleted."

    # return true if our action succeeded
    true
  end

  def userinfo(username, extended = false)
    # we can bail if we don't want to add to the basic user object.
    # for example, if these are heavy operations.
    return unless extended

    # return a hash with the :username key
    {
      :username => username,
      :example  => username.upcase,
    }
  end

  def deploy(username)
    environment = Puppetfactory::Helpers.environment_name(username)
    $logger.info "Deployed environment #{environment} for #{username}"

    # return true if our action succeeded
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

    # return true if our action succeeded
    true
  end

  # used by container plugins to rebuild them
  def repair(username)
    $logger.info "Container #{username} repaired"
    true
  end

  # hook called when users log in. Only one can be active at any time.
  def login
    $logger.info 'Logging in with the default system shell'
    exec('bash --login')
  end

  # returns an array of all user accounts. Only one can be active at any time.
  def users
    usernames = Dir.glob('/home/*').map { |path| File.basename path }
    usernames.reject { |username| ['centos', 'training', 'showoff'].include? username }
  end

end
