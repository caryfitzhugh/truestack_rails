require 'truestack_rails/railtie_3_0'
require 'truestack_rails/railtie_3_1'
require 'truestack_rails/railtie_3_2'

module TruestackRails
  class Railtie < ::Rails::Railtie
    config.before_initialize do
      TruestackRails.init_rails
    end
  end

  ## Attach to all of the different events based
  # on what rails version you are
  def self.init_rails
    TruestackClient.configure do |c|
      data = YAML.load_file("#{Rails.root}/config/truestack.yml").symbolize_keys
      c.host   = data[:host]
      c.secret = data[:secret]
      c.key    = data[:key]
      c.logger = Rails.logger
    end

    case (::Rails.version.to_f * 10.0).to_i / 10.0
    when 3.0
      TruestackRails::Railtie30.connect!
    when 3.1
      TruestackRails::Railtie31.connect!
    when 3.2
      TruestackRails::Railtie32.connect!
    else
      raise "Truestack does not support this version of Rails"
    end
  end

  # These will track the methods
  def self.reset_methods
    @_ts_start_time = Time.now
    @_ts_methods = Hash.new {|h,k| h[k] = [] }
  end

  def self.track_called_method(name, tstart, tend)
    @_ts_methods[name] << [tstart, tend]
  end

  def self.track_methods_results
    @_ts_methods
  end

  module TruestackMethodWrapper
    def method_added(method)
      definition_location = self.instance_method(method)

      if (definition_location)
        definition_location = definition_location.source_location.first
        #TruestackMethodWrapper.path_wildcards.each do |path|
        path = Rails.root.to_s
        if (definition_location =~ /^#{Regexp.escape(path)}/)
          self.class_eval <<CODE
          alias :truestack_#{method} :#{method}
          def #{method}(*args, &block)
            retval = nil
            ActiveSupport::Notifications.instrument("truestack.method_call") do
              if block_given?
                retval = truestack_#{method}(*args, &block)
              else
                retval = truestack_#{method}(*args)
              end
            end
            retval
          end
CODE
          TruestackClient.logger.info "Wrapped method #{self}##{method} - #{definition_location}"
        end
      end
    end

    def singleton_method_added(method)
      definition_location = self.method(method)
      if (definition_location)
        definition_location = definition_location.source_location.first
        path = Rails.root.to_s
        #TruestackMethodWrapper.path_wildcards.each do |path|
        if (definition_location =~ /^#{Regexp.escape(path)}/)
          TruestackClient.logger.info "HOW TO WRAP SELF. CALLS??  Wrapped method #{self}#self.#{method} - #{definition_location}"
        end
      end
    end
  end

end

class Module
  def included(klass)
    if klass.respond_to?(:method_added)
      self.instance_methods.each do |method|
        klass.method_added(method)
      end
    end
  end
end
