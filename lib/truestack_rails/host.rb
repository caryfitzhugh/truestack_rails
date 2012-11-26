require 'sys/host'
require 'grit'
require 'digest/md5'

module TruestackRails
  module Host
    def self.report_once!
      if (!@_truestack_sent_report)
        @_truestack_sent_report = Time.now
        self.report!
      end
    end

    def self.scm_version
      # If on heroku or something else with a helpful env
      version = ENV['COMMIT_HASH']
      # Otherwise try this
      if version.blank?
        begin
          version = Grit::Repo.new(Rails.root).head.commit.id
        rescue Exception => e
          # Ack. Fallback..
          methods = TruestackRails::Instrument.instrumented_methods
          version = "MD5:#{Digest::MD5.hexdigest(methods.to_json)}"
        end
      end
      version
    end

    def self.report!
      Momentarily.next_tick do
        begin
          methods = TruestackRails::Instrument.instrumented_methods
          host_id = "#{Sys::Host.host_id.to_s}/#{Sys::Host.ip_addr.join(',')}/#{Process.pid }/#{Rails.env}"

          TruestackClient.startup(self.scm_version, host_id, methods)
        rescue Exception => e
          TruestackClient.logger.info "Exception reporting! #{e}"
          TruestackClient.logger.info "Exception backtrace! #{e.backtrace.join("\n")}"
        end
      end
    end

  end
end
