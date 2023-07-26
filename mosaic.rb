require 'optparse'
require 'tempfile'

# デフォルトのオプション
options = {
  mokuroku_url: 'https://maps.gsi.go.jp/xyz/experimental_bvmap/mokuroku.csv.gz',
  template_url: 'https://maps.gsi.go.jp/xyz/optimal_bvmap-v1/{z}/{x}/{y}.pbf',
  minimum_zoom: 4,
  maximum_zoom: 16,
  gzcat: 'gzcat'
}

OptionParser.new do |opts|
  opts.banner = "Usage: mosaic [options]"

  opts.on("--mokuroku-url URL", "地理院地図Vectorタイルのmokuroku.csv.gzファイルのURLを指定") do |url|
    options[:mokuroku_url] = url
  end

  opts.on("--template-url URL", "国土地理院最適化ベクトルタイルのテンプレートURLを指定") do |url|
    options[:template_url] = url
  end

  opts.on("--minimum-zoom ZOOM", Integer, "出力するベクトルタイルの最小ズームレベルを指定") do |zoom|
    options[:minimum_zoom] = zoom
  end

  opts.on("--maximum-zoom ZOOM", Integer, "出力するベクトルタイルの最大ズームレベルを指定") do |zoom|
    options[:maximum_zoom] = zoom
  end

  opts.on("--gzcat CMD", "GZip ファイルを標準出力に展開するコマンド名を指定") do |cmd|
    options[:gzcat] = cmd
  end
end.parse!

mokuroku = Kernel.open("| curl --silent #{options[:mokuroku_url]} | gzcat")
mokuroku.each do |l|
  (z, x, y) = l.split(',')[0].split('/').map{|v| v.to_i}
  next if z < options[:minimum_zoom] or z > options[:maximum_zoom]
  url = options[:template_url].sub('{z}', z.to_s).sub('{x}', x.to_s).sub('{y}', y.to_s)
  $stderr.print url, "\n"
  Tempfile.create('mosaic') do |f|
    path = f.path
    system "curl --retry 7 --silent -o #{path} #{url}"
    system "tippecanoe-decode -f -c #{path} #{z} #{x} #{y} | tippecanoe-json-tool"
  end
end
