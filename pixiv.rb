require './msgq.rb'
require './util.rb'
require 'uri'
require 'csv'

class Pixiv
	class SearchResponse < CSV
		TAGS = [
			"user_id","user_id2", "extension","title","server_no",
			"user_name","illust_128_url","x1","x2","illust_480mw_url",
			"x3","x4","illust_entry_dt","tags","tool_name",
			"evaluate_cnt","evaluate_sum","view_cnt","caption","page_cnt",
			"x5","x6","x7","x8","user_disp_id",
			"x9","r18_flg","x10","x11","user_url"]
		def initialize(str)
			@records = CSV.parse str
		end
		def [] (idx, key)
			# p "[](#{idx}, #{key}), #{key2idx key}"
			# p @records[idx]
			@records[idx][key2idx key]
		end
		def random_image_message
			cnt = rand(count)
			caption = self.[](cnt, "caption")
			"#{caption}\n#{self.[](cnt, "illust_480mw_url")}".force_encoding("UTF-8")
		end
		def count
			@records.length
		end
		def key2idx(key)
			TAGS.each_with_index do |e, i|
				return i if e == key
			end
			raise "illust not found"
			nil
		end
	end
	def self.search_url(word)
		"http://spapi.pixiv.net/iphone/search.php?&s_mode=s_tag&word=#{URI.encode(word)}&order=date&PHPSESSID=0&p=1"
	end
	def self.search(word)
		out = `curl -fsSL \"#{Pixiv.search_url word}\"`
		SearchResponse.new out
	end
	def self.fetch(request)
		msg = Util::SlackMessage.new request
		# msg.do_parse "channel_name=lua-products&command=/hoge"
		# fetch one url of pixiv
		if msg.command =~ /\/pixiv\s+(.*)/ then
			pics = Pixiv.search URI.decode($1)
		else
			pics = Pixiv.search "あやかし陰陽"
		end
		# store it to queue
		MsgQ.push("##{msg.channel_name}", pics.random_image_message)
	end
end
