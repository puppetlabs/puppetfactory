require 'json'
require 'puppetfactory'

class Puppetfactory::Plugins::ConsoleUser < Puppetfactory::Plugins

  def initialize(options)
    super(options)

    @puppet   = options[:puppet]
    @suffix   = options[:usersuffix]
    auth_info = options[:auth_info] || {}

    @ca_certificate_path = auth_info[:ca_certificate_path] || "#{options[:confdir]}/ssl/ca/ca_crt.pem",
    @certificate_path    = auth_info[:certificate_path]    || "#{options[:confdir]}/ssl/certs/#{options[:master]}.pem",
    @private_key_path    = auth_info[:private_key_path]    || "#{options[:confdir]}/ssl/private_keys/#{options[:master]}.pem"
    @classifier_url      = options[:classifier]            || "http://#{options[:master]}:4433/classifier-api"
  end

  def create(username, password)
    output, status = Open3.capture2e(@puppet, 'resource', 'rbac_user', username,
                              'ensure=present',
                              "display_name=#{username}",
                              'roles=Operators',
                              "email=#{username}@#{@suffix}",
                              "password=#{password}")

    unless status.success
      $logger.error "Could not create PE Console user #{username}: #{output}"
      return false
    end

    $logger.info "Console user #{username} created successfully"
    true
  end

  def delete(username)
    output, status = Open3.capture2e(@puppet, 'resource', 'rbac_user', username, 'ensure=absent')
    unless status.success?
      $logger.warn "Could not remove PE Console user #{username}: #{output}"
      return false
    end

    $logger.info "Console user #{username} removed successfully"
    true
  end

  def userinfo(username, extended = false)
    return unless extended

    output, status = Open3.capture2e(PUPPET, 'resource', 'rbac_user', username)
    unless status.success?
      $logger.error "Could not query Puppet user #{username}: #{output}"
      return false
    end

    {
      :username     => username,
      :console_user => output =~ /present/,
    }
  end

end
