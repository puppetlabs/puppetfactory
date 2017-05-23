require 'json'
require 'puppetfactory'

class Puppetfactory::Plugins::Hooks < Puppetfactory::Plugins
  attr_reader :weight

  def initialize(options)
    super(options)

    @weight = 1
    @path   = options[:hooks_path] || '/etc/puppetfactory/hooks'
  end

  def create(username)
    call_hooks(:create, username)
  end

  def delete(username)
    call_hooks(:delete, username)
  end

  private
  def call_hooks(hook_type, username)
    success = true
    # the .to_s allows us to accept strings or symbols
    Dir.glob("#{HOOKS_PATH}/#{hook_type.to_s}/*") do |hook|
      next unless File.file?(hook)
      next unless File.executable?(hook)

      begin
        output, status = Open3.capture2e(hook, username)
        raise "Execution error: #{output}" unless status.success?
        $logger.info output

      rescue => e
        $logger.error "Error running hook: #{hook}"
        $logger.error e.message
        success = false
      end
    end

    # only true if all hooks succeeded.
    success
  end

end
