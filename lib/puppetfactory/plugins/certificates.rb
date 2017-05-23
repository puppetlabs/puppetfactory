require 'puppetfactory'
class Puppetfactory::Plugins::Certificates < Puppetfactory::Plugins

  def initialize(options)
    super(options)

    @puppet = options[:puppet]
    @suffix = options[:usersuffix]
  end

  def delete(username)
    certname = "#{username}.#{@suffix}"

    output, status = Open3.capture2e('puppet', 'cert', 'clean', certname)
    unless status.success?
      $logger.warn "Error cleaning certificate #{certname}: #{output}"
      return false
    end

    $logger.info "Certificate #{certname} removed"
    true
  end

  def repair(username)
    delete(username)
  end

end
