require 'sinatra'
require 'json'
require 'slack-notifier'
require './timecard.rb'
require './msgq.rb'
require './pixiv.rb'

use Rack::Auth::Basic, "Restricted Area" do |username, password|
  username == 'admin' and password == 'tcadmin'
end

settings = JSON.parse File.open('settings.json').read
client = Slack::Notifier.new(settings["team"], settings["token"], username: settings["user"])

# setup task timer
MsgQ.init do |e|
	client.ping e.message.force_encoding("UTF-8"), channel: e.channel, attachments: [e.attachments]
	puts "send message to #{e.channel}"
end

get "/ping" do
	"alive"
end
post "/timecard" do
	Timecard.punch request
	status 200
end
get "/cmd/pixiv" do
	Pixiv.fetch request
	status 200
end
