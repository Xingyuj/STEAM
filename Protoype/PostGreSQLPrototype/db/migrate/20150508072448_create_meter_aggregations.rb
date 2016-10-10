class CreateMeterAggregations < ActiveRecord::Migration
  def change
#    create_table :meter_aggregations do |t|
#      t.string :meter_serial
#      t.date :date
#      t.time :start_time
#      t.time :end_time
#      t.float :value
#      t.timestamps null: true
#    end

    execute "CREATE TABLE meter_aggregations (meter_serial VARCHAR(12) NOT NULL, date DATE NOT NULL, start_time INT, end_time INT, aggregation float);"
    add_index :meter_aggregations, :meter_serial, unique: false
    add_index :meter_aggregations, :date, unique: false
    add_index :meter_aggregations, :start_time, unique: false
    add_index :meter_aggregations, :end_time, unique: false

  end
end
