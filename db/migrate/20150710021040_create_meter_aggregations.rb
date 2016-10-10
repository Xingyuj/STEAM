class CreateMeterAggregations < ActiveRecord::Migration
  def change
    create_table :meter_aggregations do |t|
      t.integer :meter_id, :index => true, unique: false, :null => false
      t.column :register, "varchar(10)", :index => true, unique: false, :null => false
      t.date :date, :index => true, unique: false, :null => false
      t.time :start_time, :index => true, unique: false, :null => false
      t.time :end_time, :index => true, unique: false, :null => false
      t.column :unit_of_measurement, "varchar(4)", :null => false
      t.float :usage, :null => false
    end
  end
end
