Puppet::Type.type(:host).provide(:classroom,
  :parent         => :parsed,
  :default_target => File.expand_path("~/etc/hosts"),
  :filetype       => :flat,
  :record_type    => :parsed,
) do
  confine :exists => File.expand_path("~/etc")
  confine :role   => :student

  defaultfor :osfamily => :redhat
  defaultfor :role     => :student

  class << Puppet::Type.type(:host).provider(:parsed)
    attr_reader :record_types, :record_order
  end

  @record_types = Puppet::Type.type(:host).provider(:parsed).record_types
  @record_order = Puppet::Type.type(:host).provider(:parsed).record_order

  def initialize(resource)
    super
    @property_hash[:record_type] = :parsed
  end
end
