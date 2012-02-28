require 'truestack_rails/railtie_3_0'
require 'truestack_rails/railtie_3_1'
require 'truestack_rails/railtie_3_2'

module TruestackRails
  class Railtie < ::Rails::Railtie
    config.before_initialize do
      TruestackRails.init_rails(binding)
    end
  end
  ## Attach to all of the different events based
  # on what rails version you are
  def self.init_rails(binding)
    TruestackClient.configure do |c|
      data = YAML.load_file("#{Rails.root}/config/truestack.yml").symbolize_keys
      c.host   = data[:host]
      c.secret = data[:secret]
      c.key    = data[:key]
      c.logger = Rails.logger
    end

    case (::Rails.version.to_f * 10.0).to_i / 10.0
    when 3.0
      TruestackRails::Railtie30.connect!
    when 3.1
      TruestackRails::Railtie31.connect!
    when 3.2
      TruestackRails::Railtie32.connect!
    else
      raise "Truestack does not support this version of Rails"
    end
  end

  # These will track the methods
  def self.reset_methods
    @_ts_methods = []
  end

  def self.track_calling_method
    binding.pry
    parent = binding.of_caller
  end
  def self.track_methods_results(start_time)
    @_ts_methods
  end
end
