require 'yaml'

class Doppelganger
  attr_accessor :database
  @dbfile = nil

  def initialize(database)
    @dbfile = File.expand_path("~/etc/#{database}.yaml")
    @database = YAML.load_file(@dbfile) rescue {}
  end

  def get
    @database
  end

  def list
    @database.each do |name, attributes|
      puts name
      attributes.each do |name, value|
        printf("%10s: %s\n", name, value)
      end
    end
  end

  def insert(name, item = {})
    @database[name] = item
  end

  def retrieve(name)
    @database[name]
  end

  def remove(name)
    @database.delete(name)
  end

  def attribute(name, attribute, value=nil)
    @database.merge!({name => {}}) unless @database.include? name
    resource = retrieve(name)

    unless value.nil?
      resource[attribute.to_sym] = value
      save
    end

    resource[attribute.to_sym]
  end

  def save
    File.open(@dbfile, 'w') do |f|
      f.write @database.to_yaml
    end
  end
end
