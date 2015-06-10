require 'rubygems'
require 'bundler/setup'
Bundler.require(:default)

class UolDatabase < ActiveRecord::Base
  self.abstract_class = true
  establish_connection "mysql2://series:senhadohugo1!@series.mysql.uhserver.com/series"
end

class ClearDatabase < ActiveRecord::Base
  self.abstract_class = true
  establish_connection "mysql2://b30729ce3ac09f:e21e1e7e@us-cdbr-azure-east-b.cloudapp.net/cdb_d37e434bdf"
end

# series
class SerieUol < UolDatabase
	self.table_name = 'series'
end
class SerieClear < ClearDatabase
	self.table_name = 'series'
end

# episodes
class EpisodeUol < UolDatabase
	self.table_name = 'episodes'
end
class EpisodeClear < ClearDatabase
	self.table_name = 'episodes'
end

pool = Thread.pool(50)

# puts "Total: #{SerieUol.all.size}"
# SerieUol.all.each do |s|
# 	puts "ID: #{s.id}"
# 	new_serie = SerieClear.new(s.attributes)
# 	new_serie.save
# end

"Total episodes: #{SerieUol.all.size}"
eps = []
EpisodeUol.all.each do |s|
	puts "ID: #{s.id}"
	eps << EpisodeClear.new(s.attributes)
end

EpisodeClear.import eps

pool.shutdown