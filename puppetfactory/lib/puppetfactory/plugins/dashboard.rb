require 'puppetfactory'

class Puppetfactory::Plugins::Dashboard < Puppetfactory::Plugins
  attr_accessor :current_test

  def initialize(options)
    super(options)
    return unless options[:puppetfactory]

    @server   = options[:puppetfactory]
    @path     = options[:dashboard_path]     || '/etc/puppetfactory/dashboard'
    @interval = options[:dashboard_interval] || 5 * 60  # test interval in seconds

    # TODO: finish a real mutex implementation and avoid the current (small) race condition
    #set :semaphore, Mutex.new
    @current_test = 'summary'
    @test_running = false

    start_testing()

    @server.get '/dashboard' do
      protected!

      # we can't call methods directly, because this block will execute in the scope
      # of the Puppetfactory server. Use the plugin system instead.
      @current   = plugin(:Dashboard, :current_test)
      @available = plugin(:Dashboard, :available_tests)
      @test_data = plugin(:Dashboard, :test_data)

      return 'No testing data' unless @available and @test_data

      erb :dashboard
    end

    @server.get '/dashboard/details/:user' do |user|
      plugin(:Dashboard, :user_test_html, user)
    end

    @server.get '/dashboard/details/:user/:result' do |user, result|
      plugin(:Dashboard, :user_test_html, user, result)
    end

    @server.get '/dashboard/update' do
      $logger.info "Triggering dashboard update."

      if plugin(:Dashboard, :update_results)
        {'status' => 'success'}.to_json
      else
        {'status' => 'fail', 'message' => 'Already running'}.to_json
      end
    end

    @server.get '/dashboard/set/:current' do |current|
      $logger.info "Setting current test to #{current}."

      plugin(:Dashboard, :current_test=, current)

      {'status' => 'success'}.to_json
    end

  end

  def tabs(privileged = false)
    return unless privileged

    { 'dashboard' => 'Testing Dashboard' }
  end

  def update_results()
    return false if @test_running
    @test_running = true

    Dir.chdir(@path) do
      case @current_test
      when 'all', 'summary'
        system('rake', 'generate')
      else
        system('rake', 'generate', "current_test=#{@current_test}")
      end
    end

    @test_running = false
    true
  end

  def available_tests()
    Dir.chdir(@path) { `rake list`.split } rescue []
  end

  def test_data()
    JSON.parse(File.read("#{@path}/output/summary.json")) rescue {}
  end

  def user_test_html(user, result = @current_test)
    begin
    if result == 'summary'
      File.read("#{@path}/output/html/#{user}.html")
    else
      File.read("#{@path}/output/html/#{result}/#{user}.html")
    end
    rescue Errno::ENOENT
      'No results found'
    end
  end

  # class method so the template can call it
  def self.test_completion(data)
    total  = data['example_count'] rescue 0
    failed = data['failure_count'] rescue 0
    passed = total - failed
    percent = passed.to_f / total * 100.0 rescue 0

    [total, passed, percent]
  end

  private
  def start_testing()
    Thread.new do
      loop do
        $logger.info "Updating dashboard after #{@interval} seconds."
        update_results()
        sleep(@interval)
      end
    end
  end


end
