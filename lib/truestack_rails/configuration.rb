require 'logger'

module TruestackRails
  class Configuration
    CONFIG_OPTIONS = {
      :host => "http://director.truestack.com",
      :key  => "ENTER_KEY",
      :browser_tracking => true,
      :code_paths => nil,
      :environments => :production,
      :logger_path  => 'log/truestack.log'
    }

    class << self
      def code_paths
        @code ||= (self.config[:code_paths] || []).map {|p| Rails.root.join(p).to_s }
      end
      def environments
        @environments ||= [(self.config[:environments] || 'production')].flatten
      end
      def host
        self.config[:host]
      end
      def key
        self.config[:key]
      end
      def enable_browser_tracking?
        !!self.config[:browser_tracking]
      end

      def example_config_file(opts={})
        opts = CONFIG_OPTIONS.merge(opts)
        opts.to_yaml
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
