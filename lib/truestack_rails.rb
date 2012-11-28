require 'truestack_rails/instrument'
require 'truestack_rails/railtie_3_2'
require 'truestack_rails/method_tracking'
require 'truestack_rails/browser_tracking'
require 'truestack_rails/configuration'
require 'truestack_rails/host'
require 'momentarily'

# The main Truestack Rails plugin module
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
      TruestackClient.set_resource_file_location(Rails.root.join("config","truestack_uri"))

      config = TruestackRails::Configuration

      TruestackClient.configure do |c|
        c.logger = config.logger
        c.app_version = "Rails#{Rails::VERSION::STRING}:TSRails-#{TruestackRails::VERSION}"
        c.app_environment = Rails.env
      end

      if (TruestackRails::Configuration.environments.include?(Rails.env))
        case (::Rails.version.to_f * 10.0).to_i / 10.0
        when 3.2
          TruestackRails::Host.report_once!
          TruestackRails::Railtie32.instrument!
          TruestackRails::Railtie32.subscribe!
        else
          raise "Truestack does not support this version of Rails"
        end
      else
        config.logger.info "TruestackRails not enabled in this environment"
      end
    end
  end
  def self.method_name(klass, name)
    "#{klass.class.to_s}##{name}"
  end
end
