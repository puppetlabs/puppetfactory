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
    certname    = "#{username}.#{@suffix}"

    group_hash = {
      'name'               => certname,
      'environment'        => environment,
      'environment_trumps' => true,
      'parent'             => '00000000-0000-4000-8000-000000000000',
      'classes'            => {},
      'rule'               => ['or', ['=', 'name', certname]]
    }

    begin
      @puppetclassify.groups.create_group(group_hash)
    rescue => e
      $logger.error "Could not create node group #{certname}: #{e.message}"
      return false
    end

    $logger.info "Created node group #{certname} assigned to environment #{environment}"
    true
  end

  def delete(username)
    certname = "#{username}.#{@suffix}"

    begin
      group_id = @puppetclassify.groups.get_group_id(certname)
      @puppetclassify.groups.delete_group(group_id)
    rescue => e
      $logger.warn "Error removing node group #{certname}: #{e.message}"
      return false
    end

    $logger.info "Node group #{certname} removed"
    true
  end

  def userinfo(username, extended = false)
    return unless extended

    ngid = @puppetclassify.groups.get_group_id("#{username}.#{@suffix}")

    {
      :username       => username,
      :node_group_id  => ngid,
      :node_group_url => "#/node_groups/groups/#{ngid}",
    }
  end

end
