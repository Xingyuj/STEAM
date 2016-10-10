class CreateSupplyCharges < ActiveRecord::Migration
  def change
    create_table :supply_charges do |t|

      t.integer :charge_factory_id

      t.timestamps null: false
    end
  end
end
