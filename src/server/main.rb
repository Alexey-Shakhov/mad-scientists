require 'sinatra'
require 'sequel'
require 'set'
Sequel::Model.plugin :json_serializer

# The $db variable needs to be initialized before requiring this module

# Helper functions
def check_record_integrity(fields, rec, subset: false)
  return false if !subset and rec.size != fields.size

  rec.keys.each do |key|
    return false if not fields.keys.include? key.to_sym or
      rec[key].class != fields[key.to_sym]
  end

  true
end

def parse_id(string)
  return nil if !string.match(/^(\d)+$/)
  Integer(string)
end

def schema_fields(model)
  fields = {}
  model.db_schema.each do |field, info|
    next if info[:primary_key] or field == :time_added

    type = info[:type]
    fields[field] = case type
      when :string
        String
      when :integer
        Integer
    end
  end

  fields
end

# Request templates
def get_by_id(model, id)
  num = parse_id(id)
  halt 400 if !num

  record = model[{model.primary_key => num}]
  halt 404 if !record

  body record.to_json
end

def post(model, request)
  begin
    records = JSON.parse request.body.read
  rescue JSON::ParserError
    halt 400, "failed to parse JSON"
  end

  if records.class != Array
    halt 400, "invalid request body format"
  end

  fields = schema_fields model
  records.each do |rec|
    if rec.class != Hash
      halt 400, "invalid request body format"
    end

    if !check_record_integrity(fields, rec)
      halt 400, "invalid request body format"
    end
  end

  records.each do |rec|
    model.create(rec)
  end

  status 204
end

def patch(model, id)
  num = parse_id(id)
  halt 400 if !num

  record = model[{model.primary_key => num}]
  halt 404 if !record

  begin
    update = JSON.parse request.body.read
  rescue JSON::ParserError
    halt 400, "failed to parse JSON"
  end

  if update.class != Hash
    halt 400, "invalid request body format"
  end

  fields = schema_fields(model)

  if !check_record_integrity(fields, update, subset: true)
    halt 400, "invalid request body format"
  end

  update.keys.each do |key|
    record[key.to_sym] = update[key]
  end
  record.save
end

def delete(model, id)
  num = parse_id(id)
  halt 400 if !num

  if !model[{model.primary_key => num}]
    halt 404
  end

  begin
    model[{model.primary_key => num}].delete
  rescue Sequel::ForeignKeyConstraintViolation
    halt 400, 'foreign key constraint failed'
  end
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
