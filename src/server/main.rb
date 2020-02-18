require 'sinatra'
require 'sequel'
require 'net/http'
require 'set'
Sequel::Model.plugin :json_serializer

# The $db variable needs to be initialized before requiring this module

def check_record_integrity(fields, rec)
  if rec.class != Hash
    return false
  end

  # Check that there are no missing or redundant keys in the record
  if rec.size != fields.size
    return false
  end
  rec.keys.each do |key|
    if not fields.keys.include? key.to_sym
      return false
    end
  end

  rec.keys.each do |key|
    if rec[key].class != fields[key.to_sym]
      return false
    end
  end

  true
end

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
  begin
    num = Integer(id)
  rescue ArgumentError
    halt 400
  end

  if num < 1
    halt 400
  end

  record = Scientist[scientist_id: num]
  if !record
    halt 404
  else
    body record.to_json
  end
end

post '/scientists' do
  begin
    records = JSON.parse request.body.read
  rescue JSON::ParserError
    halt 400, "failed to parse JSON"
  end

  if records.class != Array
    halt 400, "invalid request body format"
  end

  fields = {name: String, madness_level: Integer,
            galaxy_destruction_attempts: Integer}

  records.each do |rec|
    if !check_record_integrity(fields, rec)
      halt 400, "invalid request body format"
    end
  end

  records.each do |rec|
    Scientist.create(rec)
  end

  status 204
end

patch '/scientists/:id' do |id|
  begin
    num = Integer(id)
  rescue ArgumentError
    halt 400
  end

  if num < 1
    halt 400
  end

  record = Scientist[scientist_id: num]
  if !record
    halt 404
  end

  begin
    update = JSON.parse request.body.read
  rescue JSON::ParserError
    halt 400, "failed to parse JSON"
  end

  if update.class != Hash
    halt 400, "invalid request body format"
  end

  fields = {name: String, madness_level: Integer,
            galaxy_destruction_attempts: Integer}

  update.keys.each do |key|
    if not fields.keys.include? key.to_sym or
        update[key].class != fields[key.to_sym]
      halt 400, "invalid request body format"
    end
  end

  update.keys.each do |key|
    record[key.to_sym] = update[key]
  end
  record.save
end

get '/devices' do
  Device.all.to_json
end
