class AddSourceToMeterAggregations < ActiveRecord::Migration
  def change
    sql = "ALTER TABLE meter_aggregations ADD source CHAR(1) DEFAULT 'r';"
    execute sql
  end
end
