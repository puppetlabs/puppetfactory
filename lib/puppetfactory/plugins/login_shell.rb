class Puppetfactory::Plugins::LoginShell < Puppetfactory::Plugins
  def initialize(options)
    super(options)
  end

  def login
    $logger.info 'Logging in with the default system shell'
    exec('bash --login')
  end
end
