module TruestackRails
  module Instrument
    # Add the method instrumentation to this base class.
    # All methods which are defined inside path_filter
    # (or defaults if not provided)
    # Will be wrapped with a _truestack method wrapper,
    # which will send out alerts through the Rails notification
    # system, and collected on each request.
    def self.instrument_methods(klass, type, path_filter=nil)
      klass.send(:extend, TruestackRails::MethodTracking)
      klass.class_eval do
        _truestack_method_type = type
        _truestack_path_filters = path_filter || TruestackClient.config.code
      end
      puts klass._truestack_method_type
    end

    # Should you instrument this method?
    def self.instrument_method?(definition_location, filter_paths)
      instrument = false
      filter_paths.each do |path|
        if (definition_location =~ /^#{Regexp.escape(path)}/)
          instrument = true
        end
      end

      instrument
    end

    def self.instrument_method!(klass, method, location, do_class_eval = true)
      code =
<<CODE
      alias :#{WRAPPED_METHOD_PREFIX}_#{method} :#{method}
      def #{method}(*args, &block)
        retval = nil
        ActiveSupport::Notifications.instrument("truestack.method_call", :klass=>self, :method=>:#{method}, :location=>'#{location}') do

          if block_given?
            retval = #{WRAPPED_METHOD_PREFIX}_#{method}(*args, &block)
          else
            retval = #{WRAPPED_METHOD_PREFIX}_#{method}(*args)
          end
        end
        retval
      end
CODE

      if ( do_class_eval )
        klass.class_eval code
      else
        klass.instance_eval code
      end

      self.instrumented_methods << [klass, method]
      ::Rails.logger.info "Wrapped method #{klass}##{method}"
    end

    def self.instrumented_methods
      @_ts_instrumented_methods ||= []
    end
  end
end
