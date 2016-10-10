class CreateDailyUsageCharges < ActiveRecord::Migration
  def change
    create_table :daily_usage_charges do |t|

      # network time period (start - end time)
      t.time :start_time, :end_time

      t.string :unit_of_measurement

      t.integer :charge_factory_id

      t.timestamps null: false
    end
  end
end
