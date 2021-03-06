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

      def logger
        if @logger
           @logger
        else
          target = (self.config[:logger_path] || Rails.root.join('log','truestack.log').to_s)
          if target =~ /stdout/i
            target = STDOUT
          end
          @logger = Logger.new(target)
        end
      end

      def config
        if @config
          @config
        elsif File.exists?("#{Rails.root}/config/truestack.yml")
          @config = YAML.load_file("#{Rails.root}/config/truestack.yml").symbolize_keys
        else
          puts "WARNING - truestack.yml could not be found."
          @config = {}
        end
      end
    end
  end
end
