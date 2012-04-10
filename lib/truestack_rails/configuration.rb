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
      def host
        self.config[:host]
      end
      def key
        self.config[:key]
      end
      def logger
        @logger ||= Logger.new((self.config[:logger_path] || Rails.root.join('log','truestack.log')))
      end
      def config
        @config ||= YAML.load_file("#{Rails.root}/config/truestack.yml").symbolize_keys
      end
    end
  end
end
