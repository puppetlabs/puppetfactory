require 'json'
require 'puppetfactory'

class Puppetfactory::Plugins::Github < Puppetfactory::Plugins

  def initialize(options)
    super(options)

    @gitserver   = options[:gitserver]
    @gituser     = options[:gituser]
    @controlrepo = options[:controlrepo]
    @repomodel   = options[:repomodel]
  end

  def create(username, password)
    true
  end

  def delete(username)
    true
  end

  def userinfo(username, extended = false)
    if @repomodel == :single
      controlrepo = "#{@gitserver}/#{@gituser}/#{@controlrepo.chomp('.git')}/tree/#{username}"
    else
      controlrepo = "#{@gitserver}/#{username}/#{@controlrepo.chomp('.git')}"
    end
    {
      :username    => username,
      :controlrepo => controlrepo,
    }
  end

end
