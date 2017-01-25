require 'puppetfactory'

# inherit from Puppetfactory::Plugins
class Puppetfactory::Plugins::Tree < Puppetfactory::Plugins
  attr_reader :weight

  def initialize(options)
    super(options) # call the superclass to initialize it

    @weight  = 1
    @environments = options[:environments]
  end

  def userinfo(username, extended = false)
    # we can bail if we don't want to add to the basic user object.
    # for example, if these are heavy operations.
    return unless extended
    environment = Puppetfactory::Helpers.environment_name(username)

    # return a hash with the :username key
    {
      :username => username,
      :tree     => pathwalker("#{@environments}/#{environment}", '#' ).to_json,
    }
  end

  def pathwalker(path, parent)
    accumulator = []
    Dir.glob("#{path}/*").each do |file|
      filename = File.basename file

      # this way .fixtures.yml, etc will show up
      next if ['.', '..'].include? filename

      if File.directory?(file)
        accumulator << { "id" => file, "parent" => parent, "text" => filename }
        accumulator << pathwalker(file, file)
      else
        accumulator << { "id" => file, "parent" => parent, "icon" => "jstree-file", "text" => filename }
      end
    end
    accumulator.flatten
  end

end
