module TruestackRails
  module ExceptionsLogging32
    def self.connect!
      Rails.logger.info "Rails Exception Logging 3.2"
      super
    end
  end
end
