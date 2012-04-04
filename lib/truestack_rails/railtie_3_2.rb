module TruestackRails
  module Railtie32

    def self.connect!
      TruestackClient.logger.info "Truestack Rail-Tie 3.2"

      TruestackRails.instrument_methods(ActionController::Base,  'controller')
      TruestackRails.instrument_methods(ActionController::Metal, 'controller')
      TruestackRails.instrument_methods(ActiveRecord::Base,      'model')
      TruestackRails.instrument_methods(ActionView::Base,        'helpers')

      ActiveSupport::Notifications.subscribe("truestack.method_call") do |name, tstart, tend, id, data|
        name = TruestackRails.classify_path(data[:location])
        TruestackRails.track_called_method("#{name}/#{data[:klass]}##{data[:method]}", tstart, tend)
      end

      # Gets view rendering times
      ActiveSupport::Notifications.subscribe("render_template.action_view") do |name, tstart, tend, id, data|
        name = TruestackRails.classify_path(data[:identifier])
        TruestackRails.track_called_method("#{name}", tstart, tend)
      end

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

      ActiveSupport::Notifications.subscribe("truestack.exception") do |name, tstart, tend, id, args|
        TruestackClient.logger.info( "#{args[:controller_name]}##{args[:action_name]} !!#{args[:exception]}, #{tstart.to_i}, #{tend.to_i}, #{results}")
      end

      ActiveSupport::Notifications.subscribe("truestack.request") do |name, tstart, tend, id, args|
        results = TruestackRails.track_methods_results
        TruestackRails.reset_methods

        TruestackClient.logger.info( "#{args[:controller_name]}##{args[:action_name]} #{tstart.to_i}, #{tend.to_i}, #{results}")
        begin
          TruestackClient.request("#{args[:controller_name]}##{args[:action_name]}", tstart.to_i, results)
        rescue Exception => e
          TruestackClient.logger.error "Exception on request: #{e}"
        end
      end
    end
  end
end
