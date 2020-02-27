require 'sequel'

class Device < Sequel::Model
  def before_save
    self.time_added = Time.now
  end
end
