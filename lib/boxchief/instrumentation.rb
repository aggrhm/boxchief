module Boxchief

  module Instrumentation

    def self.included(base)
      base.send :around_filter, :watch_request if base.respond_to?(:around_filter)
    end

    def watch_request
      t1 = Time.now
      begin
        yield
      rescue => exception
        t2 = Time.now
        log_request_data({time: t2-t1, error: true})
        raise exception
      else
        t2 = Time.now
        log_request_data({time: t2-t1})
      end
    end

    def log_request_data(data)
      data[:time] = data[:time] * 1000
      data[:controller] = params[:controller]
      data[:action] = params[:action]
      Rails.logger.info "REQUESTDATA: #{data.to_json}"
    end

    class RequestTable

      def initialize(lines)
        @lines = lines
        self.parse_lines
        self.build_summary
      end

      def parse_lines
        @reqs = @lines.collect do |line|
          JSON.parse(line.split("REQUESTDATA:").last.strip)
        end
      end

      def build_summary
        rm = {}
        # build request metrics with averages
        @reqs.each do |req|
          req_nm = "#{req["controller"]}##{req["action"]}"
          rm_h = rm[req_nm] ||= {count: 0, sum: 0, max: 0, name: req_nm}
          rm_h[:count] += 1
          rm_h[:sum] += (req["time"] || 0)
          rm_h[:max] = req["time"] if req["time"] > rm_h[:max]
        end

        # compute averages
        rm.each do |req_nm, stats|
          stats[:avg] = stats[:sum] / stats[:count]
        end
        @summary = rm
      end

      def longest_requests(count=10)
        return @summary.values.sort{|x, y| y[:max] <=> x[:max] }[0..(count-1)].reduce({}) {|memo, val| memo[val[:name]] = {value: val[:max]}; memo; }
      end
      def frequent_requests(count=10)
        return @summary.values.sort{|x, y| y[:count] <=> x[:count] }[0..(count-1)].reduce({}) {|memo, val| memo[val[:name]] = {value: val[:count]}; memo; }
      end


      def count
        return @reqs.length
      end

    end
    
  end

end
