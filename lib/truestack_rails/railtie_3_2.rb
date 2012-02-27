module TruestackRails
  module Railtie32
    extend TruestackRails::RequestLogging32
    extend TruestackRails::FiltersLogging32
    extend TruestackRails::ModelsLogging32
    extend TruestackRails::ExceptionsLogging32

    def self.connect!
      Rails.logger.info "Truestack Rail-Tie 3.2"
      super
    end
  end
end
