module TruestackRails
  module MethodTracking
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
end
