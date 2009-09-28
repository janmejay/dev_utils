#!/usr/bin/env ruby

contents = File.read(ARGV[0])

$o_count, $o_hour, $o_min, $o_sec, $o_mills = ARGV[2].to_i, ARGV[3].to_i, ARGV[4].to_i, ARGV[5].to_i, ARGV[6].to_i

def convert(count, start_time, end_time)
  count = count.to_i + $o_count;
  start_time = convert_time(start_time)
  end_time = convert_time(end_time)
  "#{count}
#{start_time} --> #{end_time}"
end

def convert_time time
  hr = time[0,2].to_i + $o_hour;
  min = time[3,5].to_i + $o_min;
  sec = time[6,8].to_i + $o_sec;
  mills = time[9,12].to_i + $o_mills;
  sec += mills/1000;
  mills %= 1000;
  min += sec/60;
  sec %= 60;
  hr += min/60;
  min %= 60;
  "%02d:%02d:%02d,%03d" % [hr, min, sec, mills];
end

contents.scan(/^((\d+)\s*(\d+:\d+:\d+,\d+)\s*-->\s*(\d+:\d+:\d+,\d+)\s*)$/).each do |match_data|
  contents.gsub!(match_data[0], convert(match_data[1], match_data[2], match_data[3]))
end

File.open(ARGV[1], "w") { |h| h.write(contents) }

