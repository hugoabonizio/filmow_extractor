require 'rubygems'
require 'bundler/setup'
require 'open-uri'
Bundler.require(:default)
Dotenv.load

ActiveRecord::Base.establish_connection(ENV['DATABASE_URL'])
class Serie < ActiveRecord::Base
end

def download(series)
	pool = Thread.pool(10)
	error = []
	series.each do |s|
		pool.process do
			unless File.exists? "poster/#{s.title}.jpg"
				puts "Downloading: #{s.title}"
				result = open(s.poster,	"Referer" => "http://thetvdb.com/?tab=series&id=#{rand(1_000_000)}", "User-Agent" => "Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/43.0.2357.81 Safari/537.36").read
				if result.size > 0
					File.open("poster/#{s.title}.jpg", 'wb') do |f|
						f.write result
					end
				else
					error << s
				end
			end
		end
	end
	pool.shutdown
	puts "Erro em: #{error.size}"
	sleep 5
	download(error)
end

all = Serie.all
puts "Total: #{all.size}"

download(all)
