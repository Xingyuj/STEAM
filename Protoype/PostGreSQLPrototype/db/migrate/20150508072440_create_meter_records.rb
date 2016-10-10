class CreateMeterRecords < ActiveRecord::Migration
  def change

    execute "CREATE TABLE meter_records (meter_serial VARCHAR(12), date DATE, values float[]);"
    add_column :meter_records, :meter_interval, :integer, :default => 30
    add_index :meter_records, :meter_serial, unique: false
    add_index :meter_records, :date, unique: false

  end
end