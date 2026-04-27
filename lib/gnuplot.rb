# @param lines [Array<Array(Numeric, Numeric)>]
def gnuplot lines
  require "colorutils"
  lines = lines.zip(::ColorUtils.golden_hue).map do |line, color|
    r, g, b = ::ColorUtils.hsv2rgb((color * 180 / ::Math::PI).round, 100, 50)
    rgb = (r << 16) | (g << 8) | b
    line.map{ |x, y| [x, y, rgb].join " " }.join("\n")
  end
  ::File.write "gnuplot.txt", lines.join("\n\n\n")
  cmd = "gnuplot -p -e \"set logscale xy; set term qt; plot for [i=0:#{lines.size}] 'gnuplot.txt' " \
    "index i using 1:2:3 with lines linewidth 2 linecolor rgb variable title word('#{%w{ SKJVS Sequel PStore YAML::Store }.join " "}', i+1)\""
  exec cmd
end
