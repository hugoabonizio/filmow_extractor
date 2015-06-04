require 'rubygems'
require 'bundler/setup'
Bundler.require(:default)

hydra = Typhoeus::Hydra.new max_concurrency: 50

series = []

100.times do |i|
	request = Typhoeus::Request.new("http://filmow.com/series/?pagina=#{i + 1}")
	request.on_complete do |response|
		doc = Nokogiri::HTML(response.body)
		doc.css('.wrapper .title').each do |element|
			series << element.content
		end
	end
	hydra.queue request
end

hydra.run

puts series.size