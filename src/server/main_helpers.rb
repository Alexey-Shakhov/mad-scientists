# Helper functions
require 'sequel'

def get_by_id(model, id)
  num = parse_id(id)
  halt 400 if !num

  record = model[{model.primary_key => num}]
  halt 404 if !record

  yield record
end

def check_record_integrity(fields, rec, subset: false)
  return :missing_field if !subset and rec.size < fields.size

  rec.keys.each do |key|
    return :redundant_field if not fields.keys.include? key.to_sym
    return :invalid_type if rec[key].class != fields[key.to_sym]
  end

  :success
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
