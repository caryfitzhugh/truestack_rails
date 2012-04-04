require 'truestack_rails/railtie_3_0'
require 'truestack_rails/railtie_3_1'
require 'truestack_rails/railtie_3_2'

class Module
  def included(klass)
    if klass.respond_to?(:method_added)
      self.instance_methods.each do |method|
        klass.method_added(method)
      end
    end
  end
end

module TruestackRails
  class Railtie < ::Rails::Railtie
    config.before_initialize do
      TruestackRails.init_rails
    end
  end

  ## Attach to all of the different events based
  # on what rails version you are
  def self.init_rails
    TruestackClient.configure do |c|
      data = YAML.load_file("#{Rails.root}/config/truestack.yml").symbolize_keys
      c.host   = data[:host]
      c.secret = data[:secret]
      c.key    = data[:key]
      c.logger = Rails.logger
      c.code   = data[:code]
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
    @_ts_start_time = Time.now
    @_ts_methods = Hash.new {|h,k| h[k] = [] }
  end

  def self.track_called_method(name, tstart, tend)
    @_ts_methods[name] << [tstart, tend]
  end

  def self.track_methods_results
    @_ts_methods
  end

  module TruestackMethodWrapper
    WRAPPED_METHOD_PREFIX='_truestack'
    def _truestack_wrap_method(method)
      self.class_eval <<CODE
      alias :#{WRAPPED_METHOD_PREFIX}_#{method} :#{method}
      def #{method}(*args, &block)
        retval = nil
        ActiveSupport::Notifications.instrument("truestack.method_call") do
          if block_given?
            retval = #{WRAPPED_METHOD_PREFIX}_#{method}(*args, &block)
          else
            retval = #{WRAPPED_METHOD_PREFIX}_#{method}(*args)
          end
        end
        retval
      end
CODE
      ::Rails.logger.info "Wrapped method #{self}##{method} - #{definition_location}"
    end

    def self._truestack_instrument_method?(definition_location)
      instrument = false
      TruestackClient.config.code.each do |path|
        if (definition_location =~ /^#{Regexp.escape(path)}/)
          instrument = true
        end
      end
      instrument
    end
    def method_added(method)
      puts 'method added '
      puts method

      if (method.to_s =~ /^#{WRAPPED_METHOD_PREFIX}/)
        return
      else
        puts 'instrumenting...'
        definition_location = self.instance_method(method)
        if (definition_location)
          if (TruestackMethodWrapper._truestack_instrument_method?(definition_location.source_location.first))
            _truestack_wrap_method(method)
          end
        end
      end
    end

    def singleton_method_added(method)
      if (method.to_s =~ /^#{WRAPPED_METHOD_PREFIX}/)
        return
      else
        definition_location = self.method(method)
        if (definition_location)
          if (TruestackMethodWrapper._truestack_instrument_method?(definition_location.source_location.first))
            #_truestack_wrap_method(method)
            ::Rails.logger.info "HOW TO WRAP SELF. CALLS??  Wrapped method #{self}#self.#{method} - #{definition_location}"
          end
        end
      end
    end
  end
end

class Module
  def included(klass)
    if klass.respond_to?(:method_added)
      self.instance_methods.each do |method|
        klass.method_added(method)
      end
    end
  end
end
