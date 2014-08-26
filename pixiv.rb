require './msgq.rb'
require './util.rb'
require 'uri'
require 'csv'

class Pixiv
	class SearchResponse < CSV
		def initialize(str)
			@tag = ["user_id","extension","title","server_no","user_name","illust_128_url",
				"x1","x2","illust_480mw_url","x3","x4","illust_entry_dt","tags","tool_name",
				"evaluate_cnt","evaluate_sum","view_cnt","caption","page_cnt","x5","x6","x7","x8",
				"user_disp_id","x9","r18_flg","x10","x11","user_url"]
			@records = []
			CSV.parse str do |row|
				if not @tags then
					@tags = row
				else
					row >> @records
				end
			end
		end
		def [] (idx, key)
			@records[idx][key2idx key]
		end
		def get_random_image
			self[rand(count), "illust_480mw_url"]
		end
		def count
			@records.length
		end
		def key2idx(key)
			@tags.each_with_index do |e, i|
				return i if e == key
			end
			nil
		end
	end
	def self.search_url(word)
		"http://spapi.pixiv.net/iphone/search.php?&s_mode=s_tag&word=#{URI.encode(word)}&order=date&PHPSESSID=0&p=1"
	end
	def self.search(word)
		SearchResponse.new `curl -fsSL #{Pixiv.search_url word}`
	end
	def self.fetch(request)
		msg = Util::SlackMessage.new request
		# fetch one url of pixiv
		if msg.command =~ /\/pixiv\s+(.*)/ then
			pics = Pixiv.search URI.decode($1)
		else
			pics = Pixiv.search "あやかし陰陽"
		end
		# store it to queue
		MsgQ::push("##{msg.channel_name}", pics.get_random_image, "")
	end
end
