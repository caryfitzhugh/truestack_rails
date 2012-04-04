module TruestackRails
  module Railtie32

    def self.connect!
      TruestackClient.logger.info "Truestack Rail-Tie 3.2"

      ActionController::Base.send(:extend, TruestackRails::TruestackMethodWrapper)
      ActionController::Metal.send(:extend, TruestackRails::TruestackMethodWrapper)
      ActiveRecord::Base.send(:extend, TruestackRails::TruestackMethodWrapper)
      ActionView::Base.send(:extend, TruestackRails::TruestackMethodWrapper)

      ActiveSupport::Notifications.subscribe("truestack.method_call") do |name, tstart, tend, id, data|
        TruestackRails.track_called_method("#{data[:location].gsub(Rails.root.to_s, '') }", tstart, tend)
      end

      # Gets view rendering times
      ActiveSupport::Notifications.subscribe("render_template.action_view") do |name, tstart, tend, id, data|
        TruestackRails.track_called_method("#{data[:identifier].gsub(Rails.root.to_s, '') }", tstart, tend)
        #["render_template.action_view", #2012-04-03 14:02:14 -0400, #2012-04-03 14:02:27 -0400, #"94898774de3422c89a7e", #{:identifier=> #  "/Users/cfitzhugh/working/truestack/truestack_fuzzinator/app/views/fuzz/action2.html.slim", # :layout=>"layouts/application"}]
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
            end
          end
        end
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
