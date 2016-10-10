class AddMaximumDemandToMeterAggregations < ActiveRecord::Migration
  def change
    add_column :meter_aggregations, :maximum_demand, :float
  end
end
