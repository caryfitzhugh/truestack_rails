module TruestackRails
  module FiltersLogging32
    def self.connect!
      Rails.logger.info "Rails Filter Logging 3.2"
      super
    end
  end
end
