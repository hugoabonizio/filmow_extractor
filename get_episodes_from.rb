require 'rubygems'
require 'bundler/setup'
Bundler.require(:default)
Dotenv.load

hydra = Typhoeus::Hydra.new
SERIE_ID = 29

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
serie = Serie.find SERIE_ID

result = tvdb.fetch_series_from_data(title: serie[:original_title])
if result.nil?
	puts 'Nao deu'
else
	result.episodes.each do |episode|
		pool.process {
			ep = Episode.new
			ep.serie_id = SERIE_ID
			ep.title = episode.name
			ep.episode = episode.episode_num
			ep.season = episode.season_num
			ep.save
			}
	end
end

pool.shutdown
