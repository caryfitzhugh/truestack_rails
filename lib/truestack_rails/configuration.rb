require 'logger'

module TruestackRails
  class Configuration

    class << self

      def code_paths
        @code ||= (self.config[:code_paths] || []).map {|p| Rails.root.join(p).to_s }
      end

      def environments
        @environments ||= [(self.config[:environments] || 'production')].flatten
      end

      def enable_browser_tracking?
        !!self.config[:browser_tracking]
      end

      def logger
        if @logger
           @logger
        else
          target = (self.config[:logger_path] || Rails.root.join('log','truestack.log'))
          if target =~ /stdout/i
            target = STDOUT
          end
          @logger = Logger.new(target)
        end
      end

      def config
        @config ||= YAML.load_file("#{Rails.root}/config/truestack.yml").symbolize_keys
      end
    end
  end
end
