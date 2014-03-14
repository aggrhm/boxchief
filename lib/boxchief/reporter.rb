require 'faraday'

module Boxchief

  class Reporter

    def initialize(opts)
      @app_token = opts[:app_token]
      @server = opts[:server] || Boxchief::Utils.get_hostname
      @url = opts[:url] || "http://boxchief.com"
    end

    def report(data)
      opts = {}
      opts['app_token'] = @app_token
      opts['server'] = @server
      opts['data'] = data.to_json
      conn = Faraday.new(:url => @url)
      resp = conn.post "/api/stats/report", opts
      return resp
    end
  end

end
