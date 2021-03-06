# Request templates
require 'sinatra'
require 'sequel'

def post(model, request)
  begin
    records = JSON.parse request.body.read
  rescue JSON::ParserError
    halt 400, 'failed to parse JSON'
  end

  if records.class != Array
    halt 400, 'request body must be an array'
  end

  fields = schema_fields model

  records.each do |rec|
    if rec.class != Hash
      halt 400, 'array must only contain hashes'
    end
  end

  records.each do |rec|
    case check_record_integrity(fields, rec)
    when :missing_field
      halt 400, 'missing field in record'
    when :redundant_field
      halt 400, 'redundant field in record'
    when :invalid_type
      halt 400, 'invalid data type in record'
    end

    yield rec if block_given?
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
    halt 400, 'failed to parse JSON'
  end

  if update.class != Hash
    halt 400, 'request body must be a hash'
  end

  fields = schema_fields(model)

  update.each do |k, v|
    if not fields.keys.include? k.to_sym
      halt 400, "redundant field #{k} in record"
    end

    if v.class != fields[k.to_sym]
      halt 400, "invalid type of field #{k} in record"
    end
  end

  yield update if block_given?

  update.keys.each do |key|
    record[key.to_sym] = update[key]
  end
  record.save

  status 204
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

  status 204
end
