class CreateMeterPredictors < ActiveRecord::Migration
  def change
    create_table :meter_predictors do |t|
      t.integer :meter_id, :index => true, unique: false, :null => false
      t.time :start_time, :index => true, unique: false, :null => false
      t.time :end_time, :index => true, unique: false, :null => false
      t.date :calculated_date, :null => false
      t.timestamps null: false
    end
  end
end
