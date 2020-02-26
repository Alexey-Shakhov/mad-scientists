require 'sequel'

class Device < Sequel::Model($db[:devices])
  def before_save
    self.time_added = Time.now
  end
end
