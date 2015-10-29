require "json"
require "faraday"
require "active_support/core_ext/hash"
require "boxchief/version"
require "boxchief/utils"
require "boxchief/reporter"
require "boxchief/instrumentation"
require "boxchief/log_table"
require "boxchief/log_tables/request_table"
require "boxchief/log_tables/quick_job_table"

module Boxchief
  # Your code goes here...
  def self.report_stats(data, opts)
    url = opts[:url] || "http://boxchief.com"
    rep = {}.merge(opts)
    rep['data'] = data.to_json
    conn = Faraday.new(:url => url)
    resp = conn.post "/api/stats/report", rep
    return resp
  end

  def self.report_events(events, opts)
    url = opts[:url] || "http://boxchief.com"
    rep = {}.merge(opts)
    rep['events'] = events.to_json
    conn = Faraday.new(:url => url)
    resp = conn.post "/api/events/report", rep
    return resp
  end

  def self.log_profile(name, data, logger)
    logger.info "#{name.to_s.upcase}_PROFILE: #{data.to_json}"
  end

  def self.log_event(action, meta, logger)
    self.log_profile(:event, {action: action, meta: meta}, logger)
  end

end
