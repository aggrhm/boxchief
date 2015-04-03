module Boxchief

  module LogTables

    class RequestTable

      def initialize(lines, prefix)
        @lines = lines
        @prefix = prefix
        self.parse_lines
        self.build_summary
      end

      def parse_lines
        @reqs = @lines.collect do |line|
          JSON.parse(line.split(@prefix).last.strip)
        end
      end

      def build_summary
        rm = {}
        # build request metrics with averages
        @reqs.each do |req|
          req_nm = "#{req["controller"]}##{req["action"]}"
          rm_h = rm[req_nm] ||= {count: 0, error_count: 0, sum: 0, max: 0, name: req_nm}
          rm_h[:count] += 1
          rm_h[:sum] += (req["time"] || 0)
          rm_h[:max] = req["time"] if req["time"] > rm_h[:max]

          if !req["error"].nil?
            rm_h[:error_count] += 1
            rm_h[:error_info] = req["error"]
          end
        end

        # compute averages
        rm.each do |req_nm, stats|
          stats[:avg] = stats[:sum] / stats[:count]
        end
        @summary = rm
      end

      def summary
        @summary
      end

      def longest_requests_map(count=10)
        return @summary.values.sort{|x, y| y[:max] <=> x[:max] }[0..(count-1)].reduce({}) {|memo, val| memo[val[:name]] = {value: val[:max].round(2)}; memo; }
      end

      def frequent_requests_map(count=10)
        return @summary.values.sort{|x, y| y[:count] <=> x[:count] }[0..(count-1)].reduce({}) {|memo, val| memo[val[:name]] = {value: val[:count]}; memo; }
      end

      def errors_map(count=10)
        return @summary.values.select{|sh| sh[:error_count] > 0}[0..(count-1)].reduce({}) do |memo, val| 
          memo[val[:name]] = {value: val[:error_count], info: val[:error_info]}
          memo
        end
      end

      def avg_queue_time
        qrs = @reqs.collect{|r| r["queue_time"]}.select{|v| !v.nil?}
        return nil if qrs.empty?
        sum = qrs.reduce(:+)
        return (sum.to_f / qrs.length).round(2)
      end

      def avg_time
        tms = @reqs.collect{|r| r["time"]}.select{|v| !v.nil?}
        return nil if tms.empty?
        sum = tms.reduce(:+)
        return (sum.to_f / tms.length).round(2)
      end

      def count
        return @reqs.length
      end

    end

  end

end
