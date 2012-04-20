module TruestackRails
  module Railtie32
    # Subscribe to all the notifications pushed out by things in the instrument method
    def self.subscribe!
      # Track method calls
      ActiveSupport::Notifications.subscribe("truestack.method_call") do |name, tstart, tend, id, data|
        TruestackRails::MethodTracking.track_called_method("#{data[:klass].class.to_s}##{data[:method]}", data[:classification], tstart, tend)
      end

      # Gets view rendering times
      ActiveSupport::Notifications.subscribe("render_template.action_view") do |name, tstart, tend, id, data|
        name = TruestackRails::Instrument.classify_path(data[:identifier])
        TruestackRails::MethodTracking.track_called_method(name, 'view', tstart, tend)
      end

      # From that request handilng, catch exceptions
      ActiveSupport::Notifications.subscribe("truestack.exception") do |name, tstart, tend, id, args|
        # def self.exception(action_name, start_time, e, request_env)
        TruestackClient.logger.info( "#{args[:controller_name]}##{args[:action_name]} Exception: #{args.to_s}")

        if (TruestackRails::Configuration.environments.include?(Rails.env))
          Momentarily.next_tick do
            begin
              TruestackClient.exception("#{args[:controller_name]}##{args[:action_name]}", tstart, args[:exception], args[:request].filtered_env  )
            rescue Exception => e
              TruestackClient.logger.error "Exception on request: #{e}"
            end
          end
        end
      end

      # From that request handilng, catch the request data.
      # Push into momentarily - so we can defer to the next_tick - so we don't block on the request.
      ActiveSupport::Notifications.subscribe("truestack.request") do |name, tstart, tend, id, args|
        results = TruestackRails::MethodTracking.track_methods_results

        TruestackClient.logger.info( "#{args[:controller_name]}##{args[:action_name]} #{args[:request_id]}:#{tstart.to_i}, #{tend.to_i}, #{results.to_yaml}")

        if (TruestackRails::Configuration.environments.include?(Rails.env))
          Momentarily.next_tick do
            begin
              TruestackClient.request("#{args[:controller_name]}##{args[:action_name]}", args[:request_id], results)
            rescue Exception => e
              TruestackClient.logger.error "Exception on request: #{e}"
            end
          end
        end
      end

      ActiveSupport::Notifications.subscribe("truestack.metric") do |name, tstart, tend, id, args|
        TruestackClient.logger.info "Tracking metric: #{args[:name]} : #{args[:value]} : #{args[:meta_data].to_json}"

        if (TruestackRails::Configuration.environments.include?(Rails.env))
          Momentarily.next_tick do
            begin
              TruestackClient.metric(tstart, args[:name], args[:value], args[:meta_data])
            rescue Exception => e
              TruestackClient.logger.error "Exception on metric: #{e}"
            end
          end
        end
      end
    end

    # Specify which classes to instrument and put various hooks in so that we can watch
    # what is going on in the application
    def self.instrument!
      Module.class_eval do
        def included(klass)
          if klass.respond_to?(:method_added)
            self.instance_methods.each do |method|
              klass.method_added(method)
            end
          end
        end
        def singleton_method_added(method)
          if (method.to_s =~ /^#{TruestackRails::WRAPPED_METHOD_PREFIX}/)
            return
          else
            begin
              definition_location = self.method(method)
              if (definition_location)
                loc = definition_location.source_location.first
                filters = TruestackRails::Configuration.code_paths
                classification = 'model'
                if (TruestackRails::Instrument.instrument_method?(loc, filters))
                  TruestackRails::Instrument.instrument_method!(self, method, loc, classification, false)
                end
              end
            rescue Exception => e
              TruestackClient.logger.error "self.#{self}##{method} Exp: #{e}"
            end
          end
        end
      end
      # Make everything that isn't specified a model level
      TruestackRails::Instrument.instrument_methods(Object,                  'model')

      # Refine a few here!
      TruestackRails::Instrument.instrument_methods(ActionController::Base,  'controller')
      TruestackRails::Instrument.instrument_methods(ActionController::Metal, 'controller')
      TruestackRails::Instrument.instrument_methods(ActionView::Base,        'helpers')

      # Add in the methods to allow you to track in the browser (do this before instrumenting the methods!)
      ActionView::Base.send(:include, TruestackRails::BrowserTracking)

      # Setup the render / request handling
      ApplicationController.class_eval do
        # Match the WRAPPED_METHOD_PREFIX
        prepend_around_filter :_truestack_request_logging_around_filter

        private
        # Match the WRAPPED_METHOD_PREFIX
        def _truestack_request_logging_around_filter
          @truestack_request_id = SecureRandom.hex(8)
          ActiveSupport::Notifications.instrument("truestack.request", :controller_name => controller_name, :action_name => action_name, :request_id=>@truestack_request_id) do
            TruestackRails::MethodTracking.reset_methods
            begin
              yield
            rescue Exception => e
              ActiveSupport::Notifications.instrument("truestack.exception", :exception => e, :request => request,  :controller_name => controller_name, :request_id=>@truestack_request_id, :action_name => action_name)
              raise e
            rescue RuntimeError => e
              ActiveSupport::Notifications.instrument("truestack.exception", :exception => e, :request => request,  :controller_name => controller_name, :request_id=>@truestack_request_id, :action_name => action_name)
              raise e
            end
          end
        end
      end
    end
  end
end
