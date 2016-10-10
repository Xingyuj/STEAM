class RemovePostgresqlRules < ActiveRecord::Migration
  def change
    rule = "DROP RULE IF EXISTS ignore_duplicate_meter_aggregations on meter_aggregations;"
    execute rule
    rule = "DROP RULE IF EXISTS ignore_duplicate_meter_records on meter_records;"
    execute rule
  end
end
