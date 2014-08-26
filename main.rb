require 'sinatra'
require 'json'
# require 'slack-notifier'
require './timecard.rb'
require './msgq.rb'
require './pixiv.rb'

use Rack::Auth::Basic, "Restricted Area" do |username, password|
  username == 'admin' and password == 'tcadmin'
end

settings = JSON.parse File.open('settings.json').read
# client = Slack::Notifier(settings["team"], settings["token"], username: settings["user"])

#EventMachine::PeriodicTimer.new(1) do
#	p "tick!!"
#	MsgQ::pop(10).each do |e|
#		client.ping e.msg, channel: e.channel, attachments: [e.attachments]
#	end
#end

get "/ping" do
	"alive"
end
get "/p2" do
	"a2"
end
post "/test" do
	"test"
end
post "/timecard" do
	Timecard.punch request
	status 200
end

post "/cmd/pixiv" do
	Pixiv.fetch request
	status 200
end
