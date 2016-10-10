class CreateCapacityCharges < ActiveRecord::Migration
  def change
    create_table :capacity_charges do |t|
      t.string :period
      t.timestamps null: false
    end
  end
end
