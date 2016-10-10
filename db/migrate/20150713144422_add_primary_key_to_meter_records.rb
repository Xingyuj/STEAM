class AddPrimaryKeyToMeterRecords < ActiveRecord::Migration
  def change
    execute "ALTER TABLE meter_records ADD CONSTRAINT composite UNIQUE (meter_id, register, date);"
  end
end
