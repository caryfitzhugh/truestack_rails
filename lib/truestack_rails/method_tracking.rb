module TruestackRails
  module MethodTracking
    self << class
      attr_accessor :_truestack_method_type, :_truestack_path_filters
    end

    def method_added(method)
puts "inside " + self.class._truestack_method_type
      if (method.to_s =~ /^#{TruestackRails::WRAPPED_METHOD_PREFIX}/)
        return
      else
        definition_location = self.instance_method(method)
        if (definition_location)
          if (TruestackRails::Instrument.instrument_method?(definition_location.source_location.first))
            TruestackRails::Instrument.instrument_method!(self, method, definition_location.source_location.first)
          end
        end
      end
    end

    def singleton_method_added(method)
      if (method.to_s =~ /^#{TruestackRails::WRAPPED_METHOD_PREFIX}/)
        return
      else
        definition_location = self.method(method)
        if (definition_location)
          if (TruestackRails::Instrument.instrument_method?(definition_location.source_location.first))
            TruestackRails::Instrument.instrument_method!(self, method, definition_location.source_location.first, false)
          end
        end
      end
    end

  end
end
