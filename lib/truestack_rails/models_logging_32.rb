module TruestackRails
  module ModelsLogging32
    def self.connect!
      Rails.logger.info "Rails Model Logging 3.2"
      super
    end
  end
end
