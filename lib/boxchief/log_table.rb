module Boxchief

  class LogTable

    def self.calc(vals, c)
      if c == :avg
        return (vals.reduce(:+).to_f / vals.length)
      elsif c == :sum
        return vals.reduce(:+)
      elsif c == :max
        return vals.max
      elsif c == :min
        return vals.min
      end
    end

    def initialize(log_path, prefix, opts={}, &block)
      @log_path = log_path
      @prefix = prefix
      @entries = []
      @name_map = {}
      @reader = Utils::LogReader.new(@log_path, @prefix)
      @namer = nil
      block.call(self) if block
    end

    def namer=(fn)
      @namer = fn
    end

    def update
      @entries = []
      # get lines from log
      lines = @reader.get_matching_lines_since || []
      @entries = lines.collect {|line|
        json = JSON.parse(line.split("#{@prefix}:").last.strip)
        e = json.with_indifferent_access
        e[:name] = @namer.call(e) if @namer
        e
      }
      self.process_entries
      return self.entries
    end

    def process_entries
      @name_map = Hash.new {|h,k| h[k] = []}
      @entries.each do |entry|
        entry[:count] ||= 1
        if !entry[:name].nil?
          @name_map[entry[:name]] << entry
        end
      end
    end

    def value(stat, calc=:avg, &block)
      es = @entries
      if block
        es = @entries.select(&block)
      end
      vals = es.collect{|e| e[stat]}.select{|v| !v.nil?}
      if vals.length == 0
        return nil
      end

      ret = LogTable.calc(vals, calc)
      return ret.round(2)
    end

    def map(stat, calc, order=:desc, opts={}, &block)
      opts[:limit] ||= 10
      nmvs = []
      #puts @name_map.inspect
      @name_map.each do |name, es|
        nes = es
        if block
          nes = es.select(&block)
        end
        vals = nes.collect{|e| e[stat]}.select{|v| !v.nil?}
        if vals.length == 0
          next
        end
        nmv = {}
        nmv[:name] = name
        nmv[:value] = LogTable.calc(vals, calc)
        if opts[:info]
          if opts[:info].is_a?(Proc)
            nmv[:info] = opts[:info].call(nes.last)
          else
            nmv[:info] = nes.last[opts[:info]]
          end
        end
        nmvs << nmv
      end
      #puts nmvs.inspect
      # sort name map
      top = nmvs.sort{|x, y|
        if order == :desc
          y[:value] <=> x[:value]
        else
          x[:value] <=> y[:value]
        end
      }[0..(opts[:limit]-1)]
      ret = {}
      #puts top.inspect
      #puts "----"
      top.each do |rv|
        nm = rv[:name]
        ret[nm] = {value: rv[:value].round(2)}
        if rv.has_key?(:info)
          ret[nm][:info]
        end
      end
      return ret
    end

    def count
      return @entries.length
    end

    def entries
      return @entries
    end

    def updated_entries
      self.update
      return self.entries
    end

  end

end
