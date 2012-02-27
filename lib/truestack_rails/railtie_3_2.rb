module TruestackRails
  module Railtie32
    extend RequestLogging32
    extend FiltersLogging32
    extend ModelsLogging32
    extend ExceptionsLogging32

    def self.connect!
      Rails.logger.info "Truestack Rail-Tie 3.2"
      super
    end
  end
end
