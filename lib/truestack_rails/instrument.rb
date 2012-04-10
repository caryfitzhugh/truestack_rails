# This truestack rails module will instrument classes
# All the hooks are exposed as ActiveSupport::Notifications
# And in the railtie we listen and subscribe to these.
#
module TruestackRails
  module Instrument
    module MethodInstrumentation
      [:_truestack_method_classification, :_truestack_path_filters].each do |meth|
        define_method(meth) do
          if (instance_variable_get("@#{meth}"))
            instance_variable_get("@#{meth}")
          elsif (superclass.respond_to?(meth))
            superclass.send(meth)
          else
            nil
          end
        end
        define_method("#{meth}=") do |x|
          instance_variable_set("@#{meth}", x)
        end
      end

      # Watch and when a method is added to a class -
      # Determine if you should wrap it - if so
      # instrument it
      def method_added(method)
        if (method.to_s =~ /^#{TruestackRails::WRAPPED_METHOD_PREFIX}/)
          return
        else
          definition_location = self.instance_method(method)
          if (definition_location)
            loc = definition_location.source_location.first
            filters = self._truestack_path_filters
            if (TruestackRails::Instrument.instrument_method?(loc, filters))
              TruestackRails::Instrument.instrument_method!(self, method, loc, self._truestack_method_classification)
            end
          end
        end
      end

      # If a singleton (self...) method was added,
      # determine if it shold be instrumented, and if so - add it!
      def singleton_method_added(method)
        if (method.to_s =~ /^#{TruestackRails::WRAPPED_METHOD_PREFIX}/)
          return
        else
          definition_location = self.method(method)
          if (definition_location)
            loc = definition_location.source_location.first
            filters = self._truestack_path_filters
            if (TruestackRails::Instrument.instrument_method?(loc, filters))
              TruestackRails::Instrument.instrument_method!(self, method, loc, self._truestack_method_classification, false)
            end
          end
        end
      end
    end

    # Add the method instrumentation to this base class.
    # All methods which are defined inside path_filter
    # (or defaults if not provided)
    # Will be wrapped with a _truestack method wrapper,
    # which will send out alerts through the Rails notification
    # system, and collected on each request.
    def self.instrument_methods(klass, classification, path_filter=nil)
      klass.send(:extend, TruestackRails::Instrument::MethodInstrumentation)
      klass._truestack_method_classification = classification
      klass._truestack_path_filters = path_filter || TruestackClient::Configuration.code_paths
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

    # Wrap a method on klass, which has a location, and classification type.
    # do_class_eval specifies whether you are to do it on the class of class
    # or instance of klass.
    def self.instrument_method!(klass, method, location, classification, do_class_eval = true)
      code =
<<CODE
      alias :#{WRAPPED_METHOD_PREFIX}_#{method} :#{method}
      def #{method}(*args, &block)
        retval = nil
        ActiveSupport::Notifications.instrument("truestack.method_call", :klass=>self, :method=>:#{method}, :classification => '#{classification}', :location=>'#{location}') do

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
      ::TruestackClient.logger.info "Wrapped method #{klass}##{method}"
    end

    # Gives you all the instrumented methods
    def self.instrumented_methods
      @_ts_instrumented_methods ||= []
    end
  end
end
