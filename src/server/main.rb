require 'sinatra'
require 'sequel'
require 'net/http'
require 'set'
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

get '/scientists/:id' do |id|
  Scientist[scientist_id: id.to_i].to_json
end

get '/devices' do
  Device.all.to_json
end

post '/scientists' do
  begin
    records = JSON.parse request.body.read.to_s
  rescue JSON::ParserError
    halt 400, "failed to parse JSON"
  end

  if records.class != Array
    halt 400, "invalid request body format"
  end

  fields = {"name": String, "madness_level": Integer,
            "galaxy_destruction_attempts": Integer}

  records.each do |rec|
    if rec.class != Hash
      halt 400, "invalid request body format"
    end

    # Check that there are no missing or redundant keys in the record
    if rec.size != fields.size
      halt 400, "invalid request body format"
    end
    rec.keys.each do |key|
      if not fields.keys.include? key.to_sym
        halt 400, "invalid request body format"
      end
    end

    rec.keys.each do |key|
      if rec[key].class != fields[key.to_sym]
        halt 400, "invalid request body format"
      end
    end
  end

  records.each do |rec|
    Scientist.create(rec)
  end

  status 204
end
