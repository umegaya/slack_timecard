require 'dbi'

module Util
	module DB
		def connect
			DBI.connect("dbi:Mysql:dokyogames:localhost", "root", "dokyogames")
		end
		def write(query)
		    dbc = DB.connect
			dbc.do(query)
			dbc.commit
		rescue DBI::DatabaseError => e
			puts "Error code:    #{e.err}"
			puts "Error message: #{e.errstr}"
			dbc.rollback
		ensure
			dbc.disconnect
		end
		def readone(query)
		    dbc = DB.connect
			return dbc.select_one(query)
		rescue DBI::DatabaseError => e
			puts "Error code:    #{e.err}"
			puts "Error message: #{e.errstr}"
		ensure
			dbc.disconnect
		end
		def read(query)
		    dbc = DB.connect
			return dbc.select(query)
		rescue DBI::DatabaseError => e
			puts "Error code:    #{e.err}"
			puts "Error message: #{e.errstr}"
		ensure
			dbc.disconnect
		end
		def tr(&block)
		    dbc = DB.connect
		    block.call dbc
			dbc.commit
		rescue DBI::DatabaseError => e
			puts "Error code:    #{e.err}"
			puts "Error message: #{e.errstr}"
			dbc.rollback
		ensure
			dbc.disconnect			
		end

		module_function :connect, :readone, :write, :tr
	end

	class SlackMessage
		attr_accessor :user_name
		attr_accessor :channel_name
		attr_accessor :timestamp
		attr_accessor :text
		attr_accessor :command
		attr_accessor :trigger_word
		def initialize(req = nil)
			parse req if req
		end
		def parse(request)
			request.body.rewind
			do_parse request.body.read
		end
		def do_parse(data)
			data.split('&').each do |r|
				# p r
		        # token=uOQ8Pk741UAuxwUyvEdkQrzA
				# team_id=T0001
				# channel_id=C2147483705
				# =test
				# timestamp=1355517523.000005
				# user_id=U2147483697
				# user_name=Steve
				# text=googlebot: What is the air-speed velocity of an unladen swallow?
				# trigger_word=googlebot:
				kv = r.split("=")
				# p "#{kv[0]} responsd? #{self.respond_to?(kv[0].to_sym)}"
				if self.respond_to?(kv[0].to_sym) then
					self.send((kv[0]+"=").to_sym, kv[1])
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
end