require 'sinatra'
require 'sequel'
Sequel::Model.plugin :json_serializer
require_relative 'main_helpers'
require_relative 'main_templates'

raise RuntimeError, "Database not initialized" unless $db

require_relative 'models/scientist'
require_relative 'models/device'

get '/scientists' do
  Scientist.all.to_json
end

get '/scientists/:id' do |id|
  get_by_id(Scientist, id)
end

post '/scientists' do
  post(Scientist, request)
end

patch '/scientists/:id' do |id|
  patch(Scientist, id)
end

delete '/scientists/:id' do |id|
  delete(Scientist, id)
end

get '/devices' do
  Device.all.to_json
end

get '/devices/:id' do |id|
  get_by_id(Device, id)
end

post '/devices' do
  post(Device, request)
end

patch '/devices/:id' do |id|
  patch(Device, id)
end

delete '/devices/:id' do |id|
  delete(Device, id)
end
