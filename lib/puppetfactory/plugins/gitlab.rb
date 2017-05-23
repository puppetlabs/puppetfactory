require 'json'
require 'puppetfactory'

class Puppetfactory::Plugins::Gitlab < Puppetfactory::Plugins

  def initialize(options)
    super(options)

    @suffix = options[:usersuffix]

    begin
      # Use default gitlab root password to get session token
      login  = {:login => 'root', :password => '5iveL!fe'}
      resp   = JSON.parse(RestClient.post('http://localhost:8888/api/v3/session', login))
      @token = resp['private_token']
    rescue => e
      raise "GitLab authentication error! (#{e.message})"
    end
  end

  def create(username, password)
    begin
      if password.length < 8
        raise "Password must be at least 8 characters"
      end

      RestClient.post('http://localhost:8888/api/v3/users',
                      {
                        :email         => "#{username}.#{@suffix}",
                        :password      => password,
                        :username      => username,
                        :name          => username,
                        :confirm       => false,
                        :private_token => @token        # TODO: this invocation does not look like the invocation below?
                      })
      end

      $logger.info "Created GitLab user #{username}."
    rescue => e
      $logger.error "Error creating GitLab user #{username}: #{e.message}"
      return false
    end

    true
  end

  def delete(username)
    begin
      users  = JSON.parse(RestClient.get('http://localhost:8888/api/v3/users', {"PRIVATE-TOKEN" => @token}))
      userid = users.select { |record| record['username'] == username }['id']
      RestClient.delete("http://localhost:8888/api/v3/users/#{userid}" , {"PRIVATE-TOKEN" => @token})

      $logger.info "Removed GitLab user #{username}."
    rescue => e
      $logger.error "Error removing GitLab user #{username}: #{e.message}"
      return false
    end

    true
  end

end
