require 'rubygems'
require 'bundler/setup'
require 'open-uri'
Bundler.require(:default)
Dotenv.load

ActiveRecord::Base.establish_connection(ENV['DATABASE_URL'])
class Serie < ActiveRecord::Base
end

pool = Thread.pool(40)
series = Serie.all
puts "Total: #{series.size}"

series.each do |s|
	puts "Downloading #{s.title}"
	pool.process {
		File.open("poster/#{rand(16 ** 32)}.jpg", 'wb') do |f|
			f.write open(s.poster,
				"Referer" => "http://thetvdb.com/?tab=series&id=79349",
				"User-Agent" => "Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/43.0.2357.81 Safari/537.36"
			).read 
		end
	}
end
pool.shutdown