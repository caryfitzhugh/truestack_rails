require 'truestack_rails/logging_3_2_request'
require 'truestack_rails/logging_3_2_exceptions'

module TruestackRails
  module Railtie32

    def self.connect!
      TruestackClient.logger.info "Truestack Rail-Tie 3.2"
      TruestackRails::Logging32Request.connect!
      TruestackRails::Logging32Exceptions.connect!
    end
  end
end
