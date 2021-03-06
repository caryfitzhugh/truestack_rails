module TruestackRails
  module MethodTracking
    # These will track the methods
    def self.reset_methods
      @_ts_start_time = Time.now
      @_ts_methods = Hash.new {|h,k| h[k] = [] }
    end

    def self.track_called_method(name, type, tstart, tend)
      @_ts_methods ||= Hash.new {|h,k| h[k] = [] }

      # {
      #      tstart
      #      tend
      #      name: klass#method
      # }
      @_ts_methods[name] << {tstart: tstart, tend: tend}
    end

    def self.track_methods_results
      @_ts_methods ||= Hash.new {|h,k| h[k] = [] }
      @_ts_methods
    end
  end
end
