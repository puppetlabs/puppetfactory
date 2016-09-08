require 'json'
require 'puppetfactory'

class Puppetfactory::Plugins::Github < Puppetfactory::Plugins

  def initialize(options)
    super(options)

    @path     = options[:dashboard_path]     || '/etc/puppetfactory/dashboard'
    @interval = options[:dashboard_interval] || 5 * 60  # test interval in seconds
  end

  def render
    erb :dashboard
  end

  def start!

  end

  def update

  end

  def available_tests
    Dir.chdir(@path) { tests=`rake list`.split }
  end

  def test_data
    JSON.parse(File.read("#{@path}/output/summary.json"))
  end

end
