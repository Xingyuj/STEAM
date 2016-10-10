class AddUomToCharges < ActiveRecord::Migration
  def change
    change_table :certificate_charges do |t|
      t.string :unit_of_measurement

      change_table :capacity_charges do |t|
        t.string :unit_of_measurement
      end
    end
  end
end
