class Puppetfactory
  class Plugins
    attr_reader :weight
    # just sets up the namespace for now

    def initialize(options=nil)
      @weight ||= 100
    end
  end
end

