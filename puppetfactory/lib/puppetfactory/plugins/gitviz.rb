require 'puppetfactory'

class Puppetfactory::Plugins::Gitviz < Puppetfactory::Plugins

  def initialize(options)
    super(options)
    return unless options[:puppetfactory]

    server = options[:puppetfactory]

    # Add a web route to the puppetfactory server. Must happen in the initializer
    server.get '/gitviz' do
      '<iframe id="gitviz" src="/explain-git-with-d3/embed.html" /><script>$("div:has(#gitviz)").css("padding", 0);$("body").css("min-width", "1150px");</script>'
    end

  end

  def tabs(privileged = false)
    # url path => display title
    { 'gitviz' => 'Git Visualization' }
  end

end
