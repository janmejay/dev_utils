#!/usr/bin/env ruby

def executing?
  ENV['_'] =~ /convert_srt\.rb$/
end

module Converter
  module Number
    def check_sanity
      raise "provide offset=X(number) for this strategy" unless offset
    end

    def convert start_no, end_no
      "{#{start_no.to_i + offset}}{#{end_no.to_i + offset}}"
    end

    def process contents
      contents.scan(/^(\{(\d+)\}\{(\d+)\})/).each do |match_data|
        contents.gsub!(match_data[0], convert(match_data[1], match_data[2]))
      end
      contents
    end
  end

  module HMS #hour min sec
    def convert(count, start_time, end_time)
      count, start_time, end_time = convert_values(count, start_time, end_time)
      "#{count}
#{start_time} --> #{end_time}"
    end

    def convert_values count, start_time, end_time
      return count.to_i + count_start, convert_time(start_time), convert_time(end_time)
    end

    def convert_time time
      "%02d:%02d:%02d,%03d" % convert_time_parts(time)
    end

    def convert_time_parts time
      hr = time[0,2].to_i + hour_start;
      min = time[3,5].to_i + min_start;
      sec = time[6,8].to_i + sec_start;
      mills = time[9,12].to_i + mills_start;
      return balance_parts_out(hr, min, sec, mills)
    end

    def balance_parts_out hr, min, sec, mills
      sec += mills/1000;
      mills %= 1000;
      min += sec/60;
      sec %= 60;
      hr += min/60;
      min %= 60;
      return hr, min, sec, mills
    end

    def process contents
      contents.scan(/^((\d+)\s*(\d+:\d+:\d+,\d+)\s*-->\s*(\d+:\d+:\d+,\d+)\s*)$/).each do |match_data|
        contents.gsub!(match_data[0], convert(match_data[1], match_data[2], match_data[3]))
      end
      contents
    end

    def check_sanity
      hour_start && min_start && sec_start && mills_start && count_start && return
      raise "provide hour_start=HH min_start=MM sec_start=SS mills_start=mmm count_start=C for this strategy"
    end
  end

  module Formula
    include HMS

    alias_method :hms_check_sanity, :check_sanity

    def check_sanity
      hms_check_sanity
      raise "provide formula=(2*x + 1) for this strategy in addition to HMS start params"  unless ENV.key?('formula')
    end

    alias_method :hmt_convert_time_parts, :convert_time_parts

    def convert_time_parts time
      hr, min, sec, mills = hmt_convert_time_parts(time)
      x = hr*60*60 + min*60 + sec
      x = Kernel.eval ENV['formula'], binding, __FILE__, __LINE__
      return balance_parts_out(0, 0, x, mills)
    end

  end
end

def processor
  raise "missing strategy='Converter::HMS' or 'Converter::Number' to use choose convertor" unless (strategy = ENV['strategy'])

  convertor = Kernel.eval(strategy, binding, __FILE__, __LINE__)

  Class.new do
    include convertor

    def initialize
      check_sanity
    end

    def method_missing method
      (val = ENV[method.to_s]) && val.to_i
    end
  end.new
end

#untested
if executing?

  raise "missing if=/foo/bar.srt for using bar.srt as input srt file" unless (in_file = ENV['if']) && File.exist?(in_file)
  contents = File.read(in_file)

  raise "missing of=/foo/bar.srt for using bar.srt as output srt file" unless (out_file = ENV['of'])

  File.open(out_file, "w") { |h| h.write(processor.process(contents)) }
end
