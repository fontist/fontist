# Temporary diagnostic: RSS by stage for one engine tier.
def st
  s = File.read("/proc/self/status")
  "rss=#{s[/VmRSS:\s+(\d+)/, 1]}kB hwm=#{s[/VmHWM:\s+(\d+)/, 1]}kB"
end

def maps_top
  rows = File.read("/proc/self/smaps").split(/^(?=[0-9a-f]+-[0-9a-f]+ )/).map do |blk|
    name = blk.lines.first.split(" ", 6)[5].to_s.strip
    [name, blk[/^Rss:\s+(\d+)/, 1].to_i]
  end
  agg = rows.group_by(&:first).transform_values { |v| v.sum(&:last) }
  agg.sort_by { |_, v| -v }.first(8).map { |n, v| "#{v}kB #{n.empty? ? '[anon]' : n}" }
end
tier = ENV.fetch("FONTISAN_ENGINE")
puts "#{tier} start #{st}"
require "json"
require "fontist"
puts "#{tier} after-fontist #{st}"
require "fontisan"
puts "#{tier} after-fontisan #{st}"
require_relative "../spec/support/performance"
puts "#{tier} after-support #{st}"
ScanPathPerformance.prepare_scan
puts "#{tier} after-setup #{st}"
paths = ScanPathPerformance.fixture_paths
Fontisan.scan(paths)
puts "#{tier} after-probe #{st} served=#{Fontisan::Engine.served_by(:scan)}"
m = ScanPathPerformance.cold_measurements(ARGV.fetch(0), paths)
puts "#{tier} after-cold #{st} iters=#{m['iterations']}"
puts "#{tier} maps: #{maps_top.join(' | ')}"
