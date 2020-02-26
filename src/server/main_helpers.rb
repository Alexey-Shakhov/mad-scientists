require 'sequel'

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
