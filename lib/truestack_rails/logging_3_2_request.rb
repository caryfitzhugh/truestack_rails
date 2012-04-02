module TruestackRails
  module Logging32Request

    def self.connect!
      TruestackClient.logger.info "Rails Request Logging 3.2"

      ApplicationController.class_eval do
        prepend_around_filter :truestack_request_logging_around_filter

        private
        def truestack_request_logging_around_filter
          # Clear
          TruestackRails.reset_methods

          stime = Time.now.to_f
          yield
          etime = Time.now.to_f

          results = TruestackRails.track_methods_results(stime)

          TruestackClient.request("#{controller_name}##{action_name}", stime.to_i, results)
        end
      end
    end
  end
end
