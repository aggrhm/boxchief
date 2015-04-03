require 'usagewatch'
require 'sys/proctable'
require 'sys/filesystem'
require 'socket'

module Boxchief

  module Utils

    def self.get_hostname
      Socket.gethostname
    end

    def self.get_cpu_usage
      Usagewatch.uw_cpuused
    end

    def self.get_memory_usage
      Usagewatch.uw_memused
    end

    def self.get_disk_usage(path)
      stat = Sys::Filesystem.stat(path)
      if stat.nil?
        return 0
      end
      (( (stat.blocks - stat.blocks_available) / stat.blocks.to_f) * 100).round(2)
    end

    def self.get_tcp_conn_count
      Usagewatch.uw_tcpused
    end

    def self.get_worker_count(pid_file_name)
      return nil if !File.exists?(pid_file_name)

      pid = File.read(pid_file_name).to_i
      Sys::ProcTable.ps.select{|p| p.ppid == pid}.length
    end

    def self.get_matching_lines(file, exp, offset)
      return nil if !File.exists?(file)

      curr_len = `wc -c #{file}`.split(' ').first.to_i

      offset = 0 if offset > curr_len

      read_len = curr_len - offset

      lines = `tail -c +#{offset+1} #{file} | head -c #{read_len} | grep "#{exp}"`.split("\n")

      return {lines: lines, offset: curr_len}
    end

    def self.collect_unicorn_data(pfx, opts)
      data = {}
      log_dir = File.join(opts[:app_path], 'log')
      pid_dir = File.join(opts[:app_path], 'tmp', 'pids')
      env = opts[:env]

      opts[:req_lr] ||= LogReader.new("#{log_dir}/#{env.to_s}.log", "REQUEST_PROFILE:")

      data["#{pfx}_unicorn_workers"] = self.get_worker_count("#{pid_dir}/unicorn.pid") || 0

      lines = opts[:req_lr].get_matching_lines_since
      unless lines.nil?
        rt = Boxchief::LogTables::RequestTable.new(lines, "REQUEST_PROFILE:")
        data["#{pfx}_requests"] = rt.count
        data["#{pfx}_request_time"] = rt.avg_time || 0
        data["#{pfx}_request_time_map"] = rt.longest_requests_map
        data["#{pfx}_request_count_map"] = rt.frequent_requests_map
        data["#{pfx}_request_error_map"] = rt.errors_map
        data["#{pfx}_request_queue_time"] = rt.avg_queue_time || 0
      end
      return data
    end

    def self.collect_job_data(opts)
      data = {}
      log_dir = File.join(opts[:app_path], 'log')
      pid_dir = File.join(opts[:app_path], 'tmp', 'pids')
      opts[:job_lr] ||= LogReader.new("#{log_dir}/job_processor.log", "JOB_PROFILE:")

      data["job_workers"] = self.get_worker_count("#{pid_dir}/job_processor.pid") || 0

      lines = opts[:job_lr].get_matching_lines_since
      unless lines.nil?
        rt = Boxchief::LogTables::QuickJobTable.new(lines, "JOB_PROFILE:")
        data["jobs_completed"] = rt.count
        data["job_time_map"] = rt.longest_jobs_map
        data["job_error_map"] = rt.errors_map
      end

      return data
    end

    ## LOGREADER
    class LogReader

      def initialize(path, exp)
        @path = path
        @exp = exp
      end

      def get_matching_lines_since
        lines = nil

        # handle empty file
        size = File.size?(@path)
        if size.nil?
          @file_offset = nil
          return nil
        end

        # update offset
        if @file_offset.nil?
          # file hasn't been read yet, so set offset to end and return nil
          @file_offset = size
          return nil
        else
          # read file from offset
          ret = Boxchief::Utils.get_matching_lines(@path, @exp, @file_offset)
          @file_offset = ret[:offset]
          lines = ret[:lines]
        end

        return lines
      end

    end

  end

end
