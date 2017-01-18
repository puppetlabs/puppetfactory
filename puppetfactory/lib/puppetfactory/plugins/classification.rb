require 'json'
require 'puppetfactory'
require 'puppetclassify'

class Puppetfactory::Plugins::Classification < Puppetfactory::Plugins

  def initialize(options)
    super(options)

    @weight    = 25
    @puppet    = options[:puppet]
    @suffix    = options[:usersuffix]
    @master    = options[:master]
    classifier = options[:classifier] || "http://#{@master}:4433/classifier-api"

    auth_info = options[:auth_info]  || {}
    auth_info['ca_certificate_path'] ||= "#{options[:confdir]}/ssl/ca/ca_crt.pem"
    auth_info['certificate_path']    ||= "#{options[:confdir]}/ssl/certs/#{options[:master]}.pem"
    auth_info['private_key_path']    ||= "#{options[:confdir]}/ssl/private_keys/#{options[:master]}.pem"

    @puppetclassify = PuppetClassify.new(classifier, auth_info)
  end

  def create(username, password)
    environment = Puppetfactory::Helpers.environment_name(username)
    certname = "#{username}.#{@suffix}"

    group_hash = {
      'name'               => "#{username}'s environment group",
      'environment'        => environment,
      'environment_trumps' => true,
      'parent'             => '00000000-0000-4000-8000-000000000000',
      'classes'            => {},
      'rule'               => ['or', ['=', 'name', certname]]
    }

    begin
      @puppetclassify.groups.create_group(group_hash)
    rescue => e
      $logger.error "Could not create node group for #{username}: #{e.message}"
      return false
    end

    $logger.info "Created node group for #{certname} assigned to environment #{environment}"
    true
  end

  def delete(username)

    begin
      group_id = @puppetclassify.groups.get_group_id("#{username}'s environment group")
      @puppetclassify.groups.delete_group(group_id)
    rescue => e
      $logger.warn "Error removing node grou for #{username}: #{e.message}"
      return false
    end

    $logger.info "Node group #{username} removed"
    true
  end

  def userinfo(username, extended = false)
    return unless extended
    certname = "#{username}.#{@suffix}"
    
    begin
      ngid = @puppetclassify.groups.get_group_id("#{username}'s environment group")
    rescue => e
      $logger.warn "Error retrieving node group for #{certname}: #{e.message}"
      return nil
    end

    {
      :username       => username,
      :node_group_id  => ngid,
      :node_group_url => "#/node_groups/groups/#{ngid}",
    }
  end

end
