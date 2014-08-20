require 'faraday'

module Boxchief

  class Reporter

    def initialize(opts)
      @options = opts
      @app_token = opts[:app_token]
      @url = opts[:url] || "http://boxchief.com"

      if @options[:container].nil? && @options[:server].nil? && @options[:host].nil?
        @options[:server] = Boxchief::Utils.get_hostname
      end
    end

    def report(data)
      rep = {}.merge(@options)
      rep['app_token'] = @app_token
      rep['data'] = data.to_json
      conn = Faraday.new(:url => @url)
      resp = conn.post "/api/stats/report", rep
      return resp
    end
  end

end
