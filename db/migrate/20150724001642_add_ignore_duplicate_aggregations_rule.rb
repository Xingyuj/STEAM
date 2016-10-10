class AddIgnoreDuplicateAggregationsRule < ActiveRecord::Migration
  def change
    rule = "CREATE OR REPLACE RULE ignore_duplicate_meter_aggregations
              AS ON INSERT TO meter_aggregations
              WHERE (EXISTS ( SELECT meter_aggregations.meter_id
              FROM meter_aggregations
              WHERE
                meter_aggregations.meter_id = new.meter_id
                AND meter_aggregations.start_time = new.start_time
                AND meter_aggregations.end_time = new.end_time
                AND meter_aggregations.date = new.date))
              DO INSTEAD NOTHING"
      execute rule
  end
end
