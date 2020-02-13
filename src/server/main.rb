require 'sinatra'
require 'sequel'
Sequel::Model.plugin :json_serializer

# The $db variable needs to be initialized before requiring this module

class Scientist < Sequel::Model($db[:scientists])
  def before_save
    self.time_added = Time.now
  end
end

class Device < Sequel::Model($db[:devices])
  def before_save
    self.time_added = Time.now
  end
end

get '/scientists' do
  Scientist.all.to_json
end

get '/devices' do
  Device.all.to_json
end
