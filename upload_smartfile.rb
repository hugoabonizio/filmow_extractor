require 'rubygems'
require 'bundler/setup'
Bundler.require(:default)
Dotenv.load

ActiveRecord::Base.establish_connection(ENV['DATABASE_URL'])

class Serie < ActiveRecord::Base
end

client = Imgur.new('cf07ab6db3c782a')
pool = Thread.pool(10)
all = Serie.where('poster NOT LIKE ?', "%imgur%")
puts "Total: #{all.size}"

all.each_with_index do |s, index|
	puts index
	if File.exists? "poster/#{s.title}.jpg"
		pool.process {
			image = Imgur::LocalImage.new("poster/#{s.title}.jpg", title: s.original_title)
			puts "Uploading: #{s.title}"
			uploaded = client.upload(image)
			puts uploaded.link
			s.poster = uploaded.link
			s.save
		}
	end
end

# image = Imgur::LocalImage.new("poster/Salem.jpg", title: 'fsdfsf')
# up = client.upload(image)
# puts up.link

pool.shutdown