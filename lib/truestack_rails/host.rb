require 'sys/host'
require 'grit'

module TruestackRails
  module Host
    def self.report_once!
      if (!@_truestack_sent_report)
        @_truestack_sent_report = Time.now
        self.report!
      end
    end
    def self.report!
      Momentarily.next_tick do
binding.pry
        repo = Grit::Repo.new(Rails.root)
        current = repo.current
        scm_version = current.id

        TruestackClient.logger.info "SCM Version: " + scm_version

        TruestackClient.logger.info "VERSION: " + Sys::Host::VERSION
        TruestackClient.logger.info "Hostname: " + Sys::Host.hostname
        TruestackClient.logger.info "IP Addresses : " + Sys::Host.ip_addr.join(',')
        TruestackClient.logger.info "Host ID: " + Sys::Host.host_id.to_s

        TruestackClient.logger.info "Info: "
        TruestackClient.logger.info Sys::Host.info.to_yaml
      end
    end

  end
end
