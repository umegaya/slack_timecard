require 'sinatra'
require 'json'
require './timecard.rb'

get "/ping" do
	"alive"
end
post "/timecard" do
	Timecard.punch request
end

