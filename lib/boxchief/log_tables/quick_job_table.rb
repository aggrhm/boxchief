module Boxchief

  module LogTables

    class QuickJobTable

      def initialize(lines)
        @lines = lines
        self.parse_lines
        self.build_summary
      end

      def parse_lines
        @jobs = @lines.collect do |line|
          JSON.parse(line.split("JOBDATA:").last.strip)
        end
      end

      def build_summary
        rm = {}
        @jobs.each do |job|
          nm = "#{job["instance_class"]}##{job["method_name"]}"
          job_time = job["run_time"] || 0
          rm_h = rm[nm] ||= {count: 0, error_count: 0, sum: 0, max: 0, name: nm}
          rm_h[:count] += 1
          rm_h[:sum] += job_time
          rm_h[:max] = job_time if job_time > rm_h[:max]
          if job["state"].to_i == 4
            rm_h[:error_count] += 1
            rm_h[:error_info] = job["error"]
          end
        end

        rm.each do |nm, stats|
          stats[:avg] = stats[:sum] / stats[:count]
        end
        @summary = rm
      end

      def summary
        @summary
      end

      def jobs
        @jobs
      end

      def longest_jobs_map(count=10)
        top = @summary.values.sort{|x, y| y[:max] <=> x[:max] }[0..(count-1)]
        top.reduce({}) do |memo, val| 
          memo[val[:name]] = {value: val[:max].round(2)}
          memo
        end
      end

      def errors_map(count=10)
        top = @summary.values.select{|sh| sh[:error_count] > 0}[0..(count-1)]
        top.reduce({}) do |memo, val| 
          memo[val[:name]] = {value: val[:error_count], info: val[:error_info]}
          memo
        end
      end

      def count
        return @jobs.length
      end


    end

  end

end
