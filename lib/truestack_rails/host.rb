require 'sys/host'

module TruestackRails
  module Host
    include Sys
    def self.report_once!
      if (!@_truestack_sent_report)
        @_truestack_sent_report = Time.now
      end
      self.report!
    end
    def self.report!
      #Momentarily.next_tick do
binding.pry
        TruestackClient.logger.info "VERSION: " + Host::VERSION
        TruestackClient.logger.info "Hostname: " + Host.hostname
        TruestackClient.logger.info "IP Addresses : " + Host.ip_addr.join(',')
        TruestackClient.logger.info "Host ID: " + Host.host_id.to_s

        TruestackClient.logger.info "Info: "
        TruestackClient.logger.info Host.info.to_yaml
      #end
    end

  end
end
