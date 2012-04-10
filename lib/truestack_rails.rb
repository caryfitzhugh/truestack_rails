require 'truestack_rails/railtie_3_0'
require 'truestack_rails/railtie_3_1'
require 'truestack_rails/railtie_3_2'
require 'truestack_rails/instrument'
require 'truestack_rails/method_tracking'
require 'truestack_rails/browser_tracking'
require 'momentarily'

module TruestackRails
    # This is a prefix which is used so we don't re-wrap
    # various methods.
    WRAPPED_METHOD_PREFIX='_truestack'

  class Railtie < ::Rails::Railtie
    config.before_initialize do
      TruestackRails.init_rails
    end
  end

  ## Attach to all of the different events based
  # on what rails version you are
  def self.init_rails
    ## Start up the momentarily thread
    Momentarily.start

    TruestackClient.configure do |c|
      data = YAML.load_file("#{Rails.root}/config/truestack.yml").symbolize_keys
      c.host   = data[:host]
      c.key    = data[:key]
      c.logger = Rails.logger
      c.code   = (data[:code] || []).map {|p| Rails.root.join(p).to_s }
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

  def self.classify_path(path)
    path = path.gsub(Rails.root.to_s, '')
    path
  end

  # These will track the methods
  def self.reset_methods
    @_ts_start_time = Time.now
    @_ts_methods = Hash.new {|h,k| h[k] = [] }
  end

  def self.track_called_method(name, type, tstart, tend)
    @_ts_methods ||= Hash.new {|h,k| h[k] = [] }

    # {    type => controller | model | helper | view | browser | lib
    #      tstart
    #      tend
    #      duration
    #      name: klass#method
    # }
    @_ts_methods[name] << {tstart: tstart, tend: tend, type: type}
  end

  def self.track_methods_results
    @_ts_methods ||= Hash.new {|h,k| h[k] = [] }
    @_ts_methods
  end
end
