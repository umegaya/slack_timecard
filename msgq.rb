require 'dbi'
require 'json'
require 'timers'
require './util.rb'

class MsgQ
	include Util

	Util::DB::write("CREATE TABLE IF NOT EXISTS slack_message_queue(
		id INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
		channel CHAR(32) NOT NULL,
		message TEXT NOT NULL,
		attachments TEXT NOT NULL,
		processed TINYINT NOT NULL
	)")
	Util::DB::tr do |dbc|
		dbc.do("DELETE FROM slack_message_queue WHERE processed != 0")
	end

	class Element
		attr_accessor :channel
		attr_accessor :message
		attr_accessor :attachments

		def initialize(ch, msg, attaches)
			@channel = ch
			@message = msg
			@attachments = (attaches or {})
		end
		def save
			Util::DB::write(
				"INSERT INTO slack_message_queue VALUES" + 
				"(NULL, '#{channel}', '#{message}', '#{JSON.generate(self.attachments)}', 0)"
			)
		end
		def self.from_row(row)
			return Element.new(row[1], row[2], (not row[3].empty?) ? JSON.parse(row[3]) : {})
		end
		def self.load(id)
			row = Util::DB::readone("SELECT * FROM slack_message_queue WHERE id = #{id}")
			raise "not found : #{id}" unless row
			return Element.from_row(row)
		end
	end

	def self.init(intv = 1, n_pop = 10, &block)
		@@timer_alive = true
		@@thread = Thread.new do
			timers = Timers::Group.new
			tick_timer = timers.every(intv) do
				begin
					MsgQ.pop(n_pop).each do |e|
						#client.ping e.msg, channel: e.channel, attachments: [e.attachments]
						block.call(e)
					end
				rescue => e
					puts e
					e.backtrace.each do |t|
						puts t
					end
				end
			end
			while @@timer_alive do
				timers.wait 
			end
		end
	end

	def self.fin
		@@timer_alive = false
		@@thread.join
	end

	def self.push(ch, msg, attaches = nil)
		Element.new(ch, msg, attaches).save
	end

	def self.pop(num = 1)
		results = []
		processed = []
		Util::DB::tr do |dbc|
			rows = dbc.select_all("SELECT * FROM slack_message_queue WHERE processed = 0 ORDER BY id ASC LIMIT #{num}")
			rows.each do |row|
				results << Element.from_row(row)
				processed << row[0]
			end
			if processed.length > 0 then
				dbc.do("UPDATE slack_message_queue SET processed = 1 WHERE id IN (#{processed.join(', ')})")
			end
		end
		return results
	end

end