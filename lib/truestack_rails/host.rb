require 'sys/host'

module TruestackRails
  module Host
    def self.report_once!
      if (!!@@_sent_report)
        @@_sent_report = Time.now
        report!
      end
    end
    def self.report!
      Momentarily.next_tick do
        include Sys

        puts "VERSION: " + Host::VERSION
        puts "Hostname: " + Host.hostname
        puts "IP Addresses : " + Host.ip_addr.join(',')
        puts "Host ID: " + Host.host_id.to_s

        puts "Info: "
        puts Host.info.to_yaml
      end
    end

  end
end
