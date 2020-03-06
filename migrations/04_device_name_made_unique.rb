require 'sequel'

Sequel.migration do
  change do
    alter_table(:devices) do
      add_unique_constraint :name
    end
  end
end
