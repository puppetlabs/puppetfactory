require 'puppetfactory'

class Puppetfactory::Plugins::Logs < Puppetfactory::Plugins

  def initialize(options)
    super(options)
    return unless options[:puppetfactory]

    @logfile = options[:logfile]
    server   = options[:puppetfactory]

    # Add a web route to the puppetfactory server. Must happen in the initializer
    server.get '/logs' do
      protected!
      erb :logs
    end

    server.get '/logs/data' do
      protected!
      plugin(:Logs, :data)
    end
  end

  def tabs(privileged = false)
    return unless privileged # only show this tab to admin users

    # url path => display title
    { 'logs' => 'Logs' }
  end

  def data
    File.read(@logfile) rescue "Cannot read logfile #{@logfile}"
  end
end
