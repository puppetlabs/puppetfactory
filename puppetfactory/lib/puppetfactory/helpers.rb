require 'puppetfactory'

class Puppetfactory::Helpers

  def self.configure(options)
    @@options = options
  end

  def self.environment_name(username)
    case @@options[:repomodel]
    when :peruser
      "#{username}_production"

    when :single
      username

    else
      raise "Invalid setting for repomodel (#{repomodel})"
    end
  end

  def self.approximate_time_difference(timestamp)
    return 'never' if timestamp.nil?

    start = Time.parse(timestamp)
    delta = (Time.now - start)

    if delta > 60
      # This grossity is rounding to the nearest whole minute
      mins = ((delta / 600).round(1)*10).to_i
      "about #{mins} minutes ago"
    else
      "#{delta.to_i} seconds ago"
    end
  end

end