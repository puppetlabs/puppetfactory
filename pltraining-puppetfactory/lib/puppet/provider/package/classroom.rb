require 'puppet/provider/package'
begin
  require 'doppelganger'

  Puppet::Type.type(:package).provide(:classroom, :parent => Puppet::Provider::Package) do
    desc "Demo fake package provider"

    confine :role => :student

    defaultfor :osfamily => :redhat
    defaultfor :role     => :student

    def self.instances
      Doppelganger.new('packages').get.collect do |package, resource|
        resource[:name] = package
        new(resource)
      end
    end

    def install(useversion = true)
      data = Doppelganger.new('packages')

      data.insert(resource[:name], {:ensure  => latest, :provider => :classroom})
      data.save
    end

    def query
      data = Doppelganger.new('packages')
      data.retrieve(resource[:name])
    end

    def uninstall
      data = Doppelganger.new('packages')
      data.remove resource[:name]
      data.save
    end

    def latest
      :present
    end

    def update
      install(false)
    end
  end

rescue LoadError => e
  Puppet.debug "Doppelganger gem not available"
end
