require 'rubygems'
require 'bundler/setup'
Bundler.require(:default)
Dotenv.load

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
				unless info['movie']['title_orig'].match(%r{((.*))\s*\(}).nil?
					series << { title: info['movie']['title'].match(%r{((.*))\s*\(})[1].strip, original_title: info['movie']['title_orig'].match(%r{((.*))\s*\(})[1].strip }
				end
			end
			hydra.queue request_json
		end
	end
	hydra.queue request
end

hydra.run
series.uniq! { |s| s[:original_title] }
puts "Total: #{series.size}"

ActiveRecord::Base.establish_connection(ENV['DATABASE_URL'])
class Serie < ActiveRecord::Base
	has_many :episodes
end
class Episode < ActiveRecord::Base
	belongs_to :serie
end

pool = Thread.pool(40)

# extract information about the serie from TVDB
tvdb = Tvdbr::Client.new('5FEC454623154441')
series.each_with_index do |serie, index|
	result = tvdb.fetch_series_from_data(title: serie[:original_title])
	unless result.nil?
		# serie
		s = Serie.new
		s.title = serie[:title]
		s.original_title = serie[:original_title]
		s.poster = result.poster
		s.save
		
		# episodes
		result.episodes.each do |episode|
			pool.process {
				ep = Episode.new
				ep.serie_id = s.id
				ep.title = episode.name
				ep.episode = episode.episode_num
				ep.season = episode.season_num
				ep.save
			}
		end
	end
end
