require 'sinatra'
require 'sequel'
Sequel::Model.plugin :json_serializer
require_relative 'main_helpers'
require_relative 'main_templates'

require_relative '../../config/database' unless ENV['APP_ENV'] == 'test'

require_relative 'models/scientist'
require_relative 'models/device'

get '/scientists' do
  headers "Content-Type" => "application/json"
  Scientist.all.to_json
end

get '/scientists/:id' do |id|
  headers "Content-Type" => "application/json"
  get_by_id(Scientist, id) do |record|
    body record.to_json
  end
end

get '/scientists/:id/devices' do |id|
  headers "Content-Type" => "application/json"
  get_by_id(Scientist, id) do |record|
    body Device.where(scientist_id: record.scientist_id).to_json
  end
end

post '/scientists' do
  begin
    records = JSON.parse request.body.read
  rescue JSON::ParserError
    halt 400, 'failed to parse JSON'
  end

  if records.class != Array
    halt 400, 'request body must be an array'
  end

  fields = schema_fields Scientist

  records.each do |rec|
    if rec.class != Hash
      halt 400, 'array must only contain hashes'
    end
  end

  names = []
  records.each do |rec|
    case check_record_integrity(fields, rec)
    when :missing_field
      halt 400, 'missing field in record'
    when :redundant_field
      halt 400, 'redundant field in record'
    when :invalid_type
      halt 400, 'invalid data type in record'
    end

    if rec['madness_level'] < 0
      halt 400, 'negative madness level'
    end

    if rec['galaxy_destruction_attempts'] < 0
      halt 400, 'negative number of galaxy destruction attempts'
    end

    if names.include? rec['name']
      halt 400, 'scientists with the same name'
    end

    if Scientist[name: rec['name']]
      halt 400, "name #{rec['name']} already in database"
    end

    names << rec['name']
  end

  records.each do |rec|
    Scientist.create(rec)
  end

  status 204
end

patch '/scientists/:id' do |id|
  patch(Scientist, id) do |update|
    if Scientist[name: update['name']]
      halt 400, "name #{update['name']} already in database"
    end
    
    if update['galaxy_destruction_attempts'] and
        update['galaxy_destruction_attempts'] < 0
      halt 400, 'negative number of galaxy destruction attempts'
    end

    if update['madness_level'] and update['madness_level'] < 0
      halt 400, 'negative madness level'
    end
  end
end

delete '/scientists/:id' do |id|
  delete(Scientist, id)
end

get '/devices' do
  headers "Content-Type" => "application/json"
  body Device.all.to_json
end

get '/devices/:id' do |id|
  headers "Content-Type" => "application/json"
  get_by_id(Device, id) do |record|
    body record.to_json
  end
end

post '/scientists/:id/devices' do |id|
  get_by_id(Scientist, id) do |record|
    begin
      records = JSON.parse request.body.read
    rescue JSON::ParserError
      halt 400, 'failed to parse JSON'
    end

    if records.class != Array
      halt 400, 'request body must be an array'
    end

    fields = schema_fields Device

    records.each do |rec|
      if rec.class != Hash
        halt 400, 'array must only contain hashes'
      end
    end

    records = records.map do |rec|
      rec[:scientist_id] = Integer(id)
      rec
    end

    names = []
    records.each do |rec|
      case check_record_integrity(fields, rec)
      when :missing_field
        halt 400, 'missing field in record'
      when :redundant_field
        halt 400, 'redundant field in record'
      when :invalid_type
        halt 400, 'invalid data type in record'
      end

      if rec["power"] < 0
        halt 400, 'negative power'
      end

      if names.include? rec['name']
        halt 400, 'devices with the same name'
      end

      if Device[name: rec['name']]
        halt 400, "name #{rec['name']} already in database"
      end

      names << rec['name']
    end

    records.each do |rec|
      Device.create(rec)
    end

    status 204
  end
end

patch '/devices/:id' do |id|
  patch(Device, id) do |update|
    if update['scientist_id'] and
        Scientist[scientist_id: update['scientist_id']].nil?
      halt 400, "no such scientist"
    end

    if update['power'] and update['power'] < 0
      halt 400, 'negative power'
    end

    if Device[name: update['name']]
      halt 400, "name #{update['name']} already in database"
    end
  end
end

delete '/devices/:id' do |id|
  delete(Device, id)
end
