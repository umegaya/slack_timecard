require 'dbi'
require 'json'
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

	class Element
		attr_accessor :channel
		attr_accessor :message
		attr_accessor :attachments

		def initialize(ch, msg, attaches)
			channel = ch
			message = msg
			attachments = attaches
		end
		def save
			Util::DB::write("INSERT INTO slack_message_queue VALUES(NULL, '#{channel}', '#{message}', '#{JSON.generate(attachments)}', 0)")
		end
		def self.from_row(row)
			return self.class.new(row[1], row[2], (not row[3].empty?) ? JSON.parse(row[3]) : {})
		end
		def self.load(id)
			row = Util::DB::readone("SELECT * FROM slack_message_queue WHERE id = #{id}")
			raise "not found : #{id}" unless row
			return self.class.from_row(row)
		end
	end

	def push(ch, msg, attaches)
		Element.new(ch, msg, attaches).save
	end

	def pop(num = 1)
		results = []
		processed = []
		Util::DB::tr do |dbc|
			rows = dbc.select("SELECT * FROM slack_message_queue WHERE processed = 0 ORDER BY id ASC LIMIT #{num}")
			rows.each do |row|
				Element.from_row(row) >> results
				row[0] >> processed
			end
			dbc.do("UPDATE slack_message_queue SET processed = 1 WHERE id IN (#{processed.join(', ')})")
		end
		return results
	end
end