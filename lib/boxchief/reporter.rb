require 'faraday'

module Boxchief

  class Reporter

    def initialize(opts = {})
      @options = opts
      @options[:interval] = 60
      @logger = nil
      self.process_options
      
      # ensure options
      if @options[:container].nil? && @options[:server].nil? && @options[:host].nil?
        @options[:server] = Boxchief::Utils.get_hostname
      end

    end

    def process_options

    end

    def run
      # logger
      @logger = Logger.new( (@options[:log_path] || '/var/log/reporter.log'), 1, 1024*1024)
      @logger.info "Running with options: #{@options.inspect}"

      # loop
      loop do
        data = build_data
        @logger.info data.inspect
        if @options[:app_token] && data
          self.report(data)
        end
        sleep @options[:interval]
      end
    end

    def build_data

    end

    def report(data)
      url = @options[:url] || "http://boxchief.com"
      rep = {}.merge(@options)
      rep['data'] = data.to_json
      conn = Faraday.new(:url => url)
      resp = conn.post "/api/stats/report", rep
      return resp
    end

    def ensure_rails_loaded
      unless defined?(Rails)
        require File.join(@options[:app_path], 'config', 'environment')
      end
    end
    
  end

end
