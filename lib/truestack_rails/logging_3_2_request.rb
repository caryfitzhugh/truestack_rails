module TruestackRails
  module Logging32Request

    def self.connect!
      TruestackClient.logger.info "Rails Request Logging 3.2"

      ActionController::Base.send(:extend, TruestackRails::TruestackMethodWrapper)
      ActionController::Metal.send(:extend, TruestackRails::TruestackMethodWrapper)
      ActiveRecord::Base.send(:extend, TruestackRails::TruestackMethodWrapper)
      ActionView::Base.send(:extend, TruestackRails::TruestackMethodWrapper)

      ActiveSupport::Notifications.subscribe("truestack.method_call") do |name, tstart, tend, id, data|
        TruestackRails.track_called_method("view##{data[:identifier].gsub(Rails.root.to_s, '') }", tstart, tend)
      end

      # Gets view rendering times
      ActiveSupport::Notifications.subscribe("render_template.action_view") do |name, tstart, tend, id, data|
        TruestackRails.track_called_method("view##{data[:identifier].gsub(Rails.root.to_s, '') }", tstart, tend)
        #["render_template.action_view", #2012-04-03 14:02:14 -0400, #2012-04-03 14:02:27 -0400, #"94898774de3422c89a7e", #{:identifier=> #  "/Users/cfitzhugh/working/truestack/truestack_fuzzinator/app/views/fuzz/action2.html.slim", # :layout=>"layouts/application"}]
      end

      ApplicationController.class_eval do
        prepend_around_filter :truestack_request_logging_around_filter

        private

        def truestack_request_logging_around_filter
          # Clear
          ActiveSupport::Notifications.instrument("truestack.request", :controller_name => controller_name, :action_name => action_name) do
            yield
          end
        end

      end

      ActiveSupport::Notifications.subscribe("truestack.request") do |name, tstart, tend, id, args|
        results = TruestackRails.track_methods_results
        TruestackRails.reset_methods

        TruestackClient.request("#{controller_name}##{action_name}", stime.to_i, results)
      end

    end
  end
end
