require 'sequel'

Sequel.migration do
  change do
    alter_table(:scientists) do
      rename_column :date_added, :time_added
    end

    alter_table(:devices) do
      rename_column :date_added, :time_added
    end
  end
end
