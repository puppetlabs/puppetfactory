begin
  require 'doppelganger'

  Puppet::Type.type(:service).provide(:classroom, :parent => :base) do
    desc "Demo fake service provider"

    confine :role => :student

    defaultfor :osfamily => :redhat
    defaultfor :role     => :student

    def self.instances
      Doppelganger.new('services').get.collect do |name, resource|
        resource[:name] = name
        new(resource)
      end
    end

    def start
      data = Doppelganger.new('services')
      data.attribute(resource[:name], :ensure, :running)
      data.save
    end

    def stop
      data = Doppelganger.new('services')
      data.attribute(resource[:name], :ensure, :stopped)
      data.save
    end

    def status
      data = Doppelganger.new('services')
      data.attribute(resource[:name], :ensure) || :stopped
    end

    def enable
      data = Doppelganger.new('services')
      data.attribute(resource[:name], :enable, true)
    end

    def disable
      data = Doppelganger.new('services')
      data.attribute(resource[:name], :enable, false)
    end

    def enabled?
      data = Doppelganger.new('services')
      data.attribute(resource[:name], :enable)
    end
  end

rescue LoadError => e
  Puppet.debug "Doppelganger gem not available"
end
