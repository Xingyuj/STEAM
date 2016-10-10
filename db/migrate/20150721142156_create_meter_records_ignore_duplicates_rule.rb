class CreateMeterRecordsIgnoreDuplicatesRule < ActiveRecord::Migration
  def change
    rule = "CREATE OR REPLACE RULE ignore_duplicate_meter_records
              AS ON INSERT TO meter_records
              WHERE (EXISTS ( SELECT meter_records.meter_id
              FROM meter_records
              WHERE
                meter_records.meter_id = new.meter_id
                AND meter_records.register = new.register AND
                meter_records.date = new.date))
              DO INSTEAD NOTHING"
    execute rule
  end
end
