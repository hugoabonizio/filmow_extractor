require 'rubygems'
require 'bundler/setup'
Bundler.require(:default)

hydra = Typhoeus::Hydra.new

series = []

(1..15).each do |i|
	request = Typhoeus::Request.new("http://filmow.com/series/?pagina=#{i}")
	request.on_complete do |response|
		doc = Nokogiri::HTML(response.body)
		# get all series in portuguese name
		doc.css('.cover.tip-movie').each do |element|
			# get link to JSON API to get original name
			id = element['href'].match(/-t([0-9]+)/)[1]
			request_json = Typhoeus::Request.new("http://filmow.com/async/tooltip/movie/?movie_pk=#{id}")
			request_json.on_complete do |json|
				info = Oj.load(json.body)
				unless info['movie']['title_orig'].match(/((.*))\s*\(/).nil?
					series << { title: info['movie']['title'].match(/((.*))\s*\(/)[1].strip, original_title: info['movie']['title_orig'].match(/((.*))\s*\(/)[1].strip }
				end
				#puts "#{info['movie']['title_orig']} (#{info['movie']['title']})"
				#puts "| #{info['movie']['title_orig']}" if info['movie']['title_orig'].match(/((.*))\s*\(/).nil? or info['movie']['title'].match(/((.*))\s*\(/).nil?
			end
			hydra.queue request_json
		end
	end
	hydra.queue request
end

hydra.run

puts series.size
series.uniq! { |s| s[:original_title] }
puts series.size

series.each_with_index do |serie, index|
	File.open("series_1/#{index}_#{serie[:original_title]}.yml", 'w') do |f|
		f.write YAML.dump(serie)
	end
end