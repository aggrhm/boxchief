require 'optparse'
require 'ostruct'
require 'logger'
require 'json'

module Boxchief

  class Reporter

    def initialize(opts = {})
      @options = opts
      @options[:interval] = 60
      @logger = nil
      @option_parser = OptionParser.new do |opts|
        opts.banner = "Usage: #{File.basename($0)} [options]"
        opts.on('-h', '--help', 'Show this message') do
          puts opts
          exit 1
        end
        opts.on('-e', '--environment=NAME', 'Specifies the environment to run under') do |e|
          @options[:env] = e.to_sym
        end
        opts.on('-t', '--app-token=TOKEN', 'Boxchief App Token') do |t|
          @options[:app_token] = t.strip
        end
        opts.on('-l', '--log-path=PATH', 'Log path') do |t|
          @options[:log_path] = t.strip
        end
        opts.on('-i', '--interval=SECONDS', 'Report interval period') do |t|
          @options[:interval] = t.to_i
        end
      end

      @options[:app_path] ||= Dir.pwd
      @options[:app_pid_path] ||= File.join(@options[:app_path], "tmp", "pids")
      @options[:app_log_path] ||= File.join(@options[:app_path], "log")
      @options[:log_path] ||= "/var/log/reporter.log"

      self.process_options
      
      # ensure options
      if @options[:container].nil? && @options[:server].nil? && @options[:host].nil?
        @options[:server] = Boxchief::Utils.get_hostname
      end

    end

    def process_options
      @option_parser.parse!(ARGV)
    end

    def prepare

    end

    def run
      # logger
      @logger = Logger.new( @options[:log_path], 1, 1024*1024)
      @logger.info "Running with options: #{@options.inspect}"

      self.prepare

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

    def get_worker_count(name)
      fp = File.join(@options[:app_pid_path], "#{name}.pid")
      Utils::get_worker_count(fp)
    end

    def app_log(name)
      return File.join(@options[:app_log_path], "#{name}.log")
    end
    
  end

end
