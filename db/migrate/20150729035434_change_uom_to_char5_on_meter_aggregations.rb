class ChangeUomToChar5OnMeterAggregations < ActiveRecord::Migration
  def change
    sql = "ALTER TABLE meter_aggregations ALTER COLUMN unit_of_measurement TYPE char(5);"
    execute sql
  end
end
