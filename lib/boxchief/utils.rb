require 'usagewatch'
require 'sys/proctable'
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
