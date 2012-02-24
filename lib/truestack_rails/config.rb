module TruestackRails
  module Config
    # TODO reload in dev environment?
    def self.config_file_path
      Rails.root.join "config", "truestack.yml"
    end
    def self.load
      if (File.exists?(config_file_path))
        @config ||= Yaml.load_file config_file_path
      else
        raise "No config/truestack.yml file found!"
      end
    end
  end
end
