class UpdateMeterRecordsChangeMeterToMeterId < ActiveRecord::Migration
  def change
    rename_column :meter_records, :meter, :meter_id
  end
end
