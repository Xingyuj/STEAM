class CreateBillings < ActiveRecord::Migration
  def change
    create_table :billings do |t|
      t.integer :start_time_hour
      t.integer :end_time_hour
    end
  end
end
