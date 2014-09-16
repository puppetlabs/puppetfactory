begin
  require 'doppelganger'

  Puppet::Type.type(:user).provide(:classroom) do
    desc "Demo fake user provider"

    confine :role => :student

    defaultfor :osfamily => :redhat
    defaultfor :role     => :student

    has_features :manages_passwords

    def self.instances
      Doppelganger.new('users').get.collect do |name, resource|
        resource[:name] = name
        new(resource)
      end
    end

    def create
      data = Doppelganger.new('users')

      data.insert(resource[:name], {
        :ensure  => :present,
        :uid      => resource[:uid]   || next_uid(data.get, 500),
        :gid      => resource[:gid]   || resource[:name],
        :home     => resource[:home]  || "/home/#{resource[:name]}",
        :shell    => resource[:shell] || '/bin/bash',
        :groups   => resource[:groups],
        :comment  => resource[:comment],
        :password => resource[:password],
        :provider => :classroom,
        })
      data.save
    end

    def exists?
      data = Doppelganger.new('users')
      data.retrieve(resource[:name])
    end

    def delete
      data = Doppelganger.new('users')
      data.remove resource[:name]
      data.save
    end

    [:comment, :home, :password, :gid, :uid, :shell, :groups].each do |prop|
      define_method(prop) do
        data = Doppelganger.new('users')
        data.attribute(resource[:name], prop)
      end

      define_method("#{prop}=") do |value|
        data = Doppelganger.new('users')
        data.attribute(resource[:name], prop, value)
      end
    end

    def next_uid(users, min)
      Puppet.debug users.inspect
      max = users.collect { |name, attributes| attributes[:uid] }.compact.max || min
      max + 1
    end
  end

rescue LoadError => e
  Puppet.debug "Doppelganger gem not available"
end
