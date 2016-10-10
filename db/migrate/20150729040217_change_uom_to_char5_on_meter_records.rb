class ChangeUomToChar5OnMeterRecords < ActiveRecord::Migration
  def change
    sql = "ALTER TABLE meter_records ALTER COLUMN unit_of_measurement TYPE char(5);"
    execute sql
  end
end
