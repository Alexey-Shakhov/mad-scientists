require 'sequel'

Sequel.migration do
  change do
    create_table :scientists do
      primary_key :scientist_id

      String :name, null: false
      Integer :madness_level, null: false
      Integer :galaxy_destruction_attempts, null: false
      DateTime :date_added, null: false
    end

    create_table :devices do
      primary_key :device_id

      String :name, null: false
      foreign_key :scientist_id, :scientists, null: false
      Integer :power, null: false
      DateTime :date_added, null: false
    end
  end
end
