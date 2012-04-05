module TruestackRails
  module Railtie32

    def self.connect!
      TruestackRails::Instrument.instrument_methods(ActionController::Base,  'controller')
      TruestackRails::Instrument.instrument_methods(ActionController::Metal, 'controller')
      TruestackRails::Instrument.instrument_methods(ActiveRecord::Base,      'model')
      TruestackRails::Instrument.instrument_methods(ActionView::Base,        'helpers')

      # Track method calls
      ActiveSupport::Notifications.subscribe("truestack.method_call") do |name, tstart, tend, id, data|
        name = TruestackRails.classify_path(data[:location])
        TruestackRails.track_called_method("#{data[:classification]}:#{name}/#{data[:klass]}##{data[:method]}", tstart, tend)
      end

      # Gets view rendering times
      ActiveSupport::Notifications.subscribe("render_template.action_view") do |name, tstart, tend, id, data|
        name = TruestackRails.classify_path(data[:identifier])
        TruestackRails.track_called_method("view:#{name}", tstart, tend)
      end

      # Setup the render / request handling
      ApplicationController.class_eval do
        prepend_around_filter :_truestack_request_logging_around_filter

        private

        def _truestack_request_logging_around_filter
          ActiveSupport::Notifications.instrument("truestack.request", :controller_name => controller_name, :action_name => action_name) do
            begin
              yield
            rescue Exception => e
              ActiveSupport::Notifications.instrument("truestack.exception", :exception => e, :controller_name => controller_name, :action_name => action_name)
              raise e
            rescue RuntimeError => e
              ActiveSupport::Notifications.instrument("truestack.exception", :exception => e, :controller_name => controller_name, :action_name => action_name)
              raise e
            end
          end
        end
      end

      # From that request handilng, catch exceptions
      ActiveSupport::Notifications.subscribe("truestack.exception") do |name, tstart, tend, id, args|
        TruestackClient.logger.info( "#{args[:controller_name]}##{args[:action_name]} !!#{args[:exception]}, #{tstart.to_i}, #{tend.to_i}")
      end

      # From that request handilng, catch the request data.
      ActiveSupport::Notifications.subscribe("truestack.request") do |name, tstart, tend, id, args|
        results = TruestackRails.track_methods_results
        TruestackRails.reset_methods

        TruestackClient.logger.info( "#{args[:controller_name]}##{args[:action_name]} #{tstart.to_i}, #{tend.to_i}, #{results.to_yaml}")
        begin
          TruestackClient.request("#{args[:controller_name]}##{args[:action_name]}", tstart.to_i, results)
        rescue Exception => e
          TruestackClient.logger.error "Exception on request: #{e}"
        end
      end
    end
  end
end
