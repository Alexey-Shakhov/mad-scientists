require 'sinatra'
require 'sequel'
require 'net/http'
require 'set'
Sequel::Model.plugin :json_serializer

# The $db variable needs to be initialized before requiring this module

def check_record_integrity(fields, rec, subset: false)
  if !subset
    if rec.size != fields.size
      return false
    end
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

def parse_id(string)
  if !string.match(/^(\d)+$/)
    return nil
  end

  num = Integer(string)

  if num < 1
    return nil
  end

  num
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
  num = parse_id(id)
  if !num
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
    if rec.class != Hash
      halt 400, "invalid request body format"
    end

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
  num = parse_id(id)
  if !num
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

  if !check_record_integrity(fields, update, subset: true)
      halt 400, "invalid request body format"
  end

  update.keys.each do |key|
    record[key.to_sym] = update[key]
  end
  record.save
end

delete '/scientists/:id' do |id|
  num = parse_id(id)
  if !num
    halt 400
  end

  if !Scientist[scientist_id: num]
    halt 404
  end

  begin
    Scientist[scientist_id: num].delete
  rescue Sequel::ForeignKeyConstraintViolation
    halt 400, 'foreign key constraint failed'
  end
end

get '/devices' do
  Device.all.to_json
end
