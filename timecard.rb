require 'dbi'
require 'json'

class Timecard
	def self.connect()
		DBI.connect("dbi:Mysql:dokyogames:localhost", "root", "dokyogames")
	end
	begin
	    dbc = Timecard.connect
		dbc.do("CREATE TABLE IF NOT EXISTS timecard(
			name CHAR(32) not null,
			date CHAR(10) not null,
			start DATETIME not null,
			end DATETIME not null,
			UNIQUE(name, date)
		)")
		dbc.commit
	rescue DBI::DatabaseError => e
		puts "Error code:    #{e.err}"
		puts "Error message: #{e.errstr}"
		dbc.rollback
	ensure
		dbc.disconnect
	end

	def self.punch(request)
		p request.params
		self.store(Util::SlackMessage.new request)
	end

	def self.store(record)
		dbc = Timecard.connect
		if dbc.select_one("SELECT * FROM timecard WHERE name = '#{record.user_name}' AND date = '#{record.date}'") then
			# update 'out' record
			dbc.do("UPDATE timecard SET end = FROM_UNIXTIME(#{record.timeval}) WHERE name = '#{record.user_name}' AND date = '#{record.date}'")
		else
			# insert 'in' and 'out' records
			dbc.do("INSERT INTO timecard VALUES('#{record.user_name}', '#{record.date}', 
				FROM_UNIXTIME(#{record.timeval}), 
				FROM_UNIXTIME(#{record.timeval}))")
		end
	rescue DBI::DatabaseError => e
		puts "Error code:    #{e.err}"
		puts "Error message: #{e.errstr}"
		dbc.rollback
	ensure
		dbc.disconnect
	end
end


