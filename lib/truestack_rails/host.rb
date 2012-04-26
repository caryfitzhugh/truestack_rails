require 'sys/host'
require 'grit'

module TruestackRails
  module Host
    def self.report_once!
      TruestackClient.logger.info "Report once! called"
      TruestackClient.logger.info "And: #{@_truestack_sent_report}"
      if (!@_truestack_sent_report)
        @_truestack_sent_report = Time.now
        self.report!
      end
    end
    def self.report!
      if (TruestackRails::Configuration.environments.include?(Rails.env))
        Momentarily.next_tick do
          TruestackClient.logger.info "Reporting..."
          begin
            repo = Grit::Repo.new(Rails.root)
            methods = TruestackRails::Instrument.instrumented_methods
            scm_version = repo.head.commit.id
            host_id = "#{Sys::Host.host_id.to_s}/#{Sys::Host.ip_addr.join(',')}/#{Process.pid }/#{Rails.env}"

            TruestackClient.startup(scm_version, host_id, methods)
          rescue Exception => e
            TruestackClient.logger.info "Exception reporting! #{e}"
            TruestackClient.logger.info "Exception backtrace! #{e.backtrace.join("\n")}"
          end
        end
      end
    end

  end
end
