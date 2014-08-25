require 'dbi'
require 'json'

class Timecard
	begin
	    @@dbc = DBI.connect("dbi:Mysql:dokyogames:timecard", "root", "dokyogames")
		@@dbc.do( "CREATE TABLE IF NOT EXISTS timecard(
			name CHAR(32) not null,
			type CHAR(8) not null,
			date CHAR(10) not null,
			at DATETIME not null,
			UNIQUE KEY (type, at)
		) " )
		@@dbc.commit
	rescue DBI::DatabaseError => e
		puts "Error code:    #{e.err}"
		puts "Error message: #{e.errstr}"
		@@dbc.rollback
	end

	class SlackMessage
		attr :user_name
		attr :timestamp
		attr :text
		attr :trigger_word
		def initialize(req = nil)
			parse req if req
		end
		def parse(request)
			request.body.rewind
			request.body.readlines.each do |r|
		        # token=uOQ8Pk741UAuxwUyvEdkQrzA
				# team_id=T0001
				# channel_id=C2147483705
				# channel_name=test
				# timestamp=1355517523.000005
				# user_id=U2147483697
				# user_name=Steve
				# text=googlebot: What is the air-speed velocity of an unladen swallow?
				# trigger_word=googlebot:
				kv = r.split("=")
				if self.respond_to?(kv[0].to_sym) then
					self.send (kv[0]+"=").to_sym kv[1]
				end
			end
		end
		def date
			t = Time.at(timestamp.to_i)
			"#{t.year}-#{t.mon}-#{t.mday}"
		end
		def timeval
			timestamp.to_i
		end
	end

	def self.punch(request)
		store(SlackMessage.new request)
	end

	def self.store(record)
		if @@dbc.select_one("SELECT FROM timecard WHERE type = 'in' and date = '#{record.date}'") then
			# update 'out' record
			@@dbc.do("UPDATE timecard SET at = '#{record.timeval}' WHERE type = 'in' and date = '#{record.date}'")
		else
			# insert 'in' and 'out' records
			@@dbc.do("INSERT INTO timecard VALUES
				('#{record.name}', 'in', '#{record.date}', #{record.timeval}),
				('#{record.name}', 'out', '#{record.date}', #{record.timeval})
			")
		end
	rescue DBI::DatabaseError => e
		puts "Error code:    #{e.err}"
		puts "Error message: #{e.errstr}"
		@@dbc.rollback
	end
end


