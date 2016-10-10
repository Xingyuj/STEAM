class CreateMeterRecords < ActiveRecord::Migration
  def change
    create_table :meter_records do |t|
      t.integer :meter, :index => true, unique: false
      t.column :register, "varchar(10)", :index => true, unique: false, :null => false
      t.date :date, :index => true, unique: false, :null => false
      t.integer :interval, :default => 30
      t.column :unit_of_measurement, "varchar(4)", :null => false
      t.column :usage, "float[]", :null => false
    end
  end
end
