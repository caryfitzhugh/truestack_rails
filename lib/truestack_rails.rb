require 'truestack_rails/railtie_3_0'
require 'truestack_rails/railtie_3_1'
require 'truestack_rails/railtie_3_2'
require 'truestack_rails/instrument'
require 'truestack_rails/method_tracking'
require 'truestack_rails/browser_tracking'
require 'truestack_rails/configuration'
require 'momentarily'

# The main Truestack Rails plugin module
#
# 'It all begins here'
module TruestackRails
  # This is a prefix which is used so we don't re-wrap
  # various methods.
  WRAPPED_METHOD_PREFIX='_truestack'

  # We want to turn everything on before we start up the system.
  class Railtie < ::Rails::Railtie
    config.before_initialize do
      ## Start up the momentarily thread
      Momentarily.start

      config = TruestackRails::Configuration
      TruestackClient.configure do |c|
        c.host   = config.host
        c.key    = config.key
        c.logger = config.logger
      end

      case (::Rails.version.to_f * 10.0).to_i / 10.0
      when 3.2
        TruestackRails::Railtie32.instrument!
        TruestackRails::Railtie32.subscribe!
      else
        raise "Truestack does not support this version of Rails"
      end

      Module.class_eval do
        def included(klass)
          if klass.respond_to?(:method_added)
            self.instance_methods.each do |method|
              klass.method_added(method)
            end
          end
        end
      end
    end
  end
end
