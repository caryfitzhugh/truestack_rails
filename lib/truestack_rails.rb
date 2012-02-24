require File.join(File.expand_path(File.dirname(__FILE__)), 'truestack_rails/config')
require File.join(File.expand_path(File.dirname(__FILE__)), 'truestack_rails/railtie_3_0')
require File.join(File.expand_path(File.dirname(__FILE__)), 'truestack_rails/railtie_3_1')
require File.join(File.expand_path(File.dirname(__FILE__)), 'truestack_rails/railtie_3_2')

module TruestackRails
  class Railtie < ::Rails::Railtie
    config.before_initialize do
      TruestackRails.init_rails(binding)
    end
  end

  ## Attach to all of the different events based
  # on what rails version you are
  def self.init_rails(binding)
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
end
