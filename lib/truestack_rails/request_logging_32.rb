module TruestackRails
  module RequestLogging32
    def self.connect!
      Rails.logger.info "Rails Request Logging 3.2"
      super
    end
  end
end
