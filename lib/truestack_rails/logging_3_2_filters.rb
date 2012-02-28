module TruestackRails
  module Logging32Filters
    def self.connect!
      TruestackClient.logger.info "Rails Filter Logging 3.2"
    end
  end
end
