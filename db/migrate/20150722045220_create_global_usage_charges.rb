class CreateGlobalUsageCharges < ActiveRecord::Migration
  def change
    create_table :global_usage_charges do |t|

      t.string :unit_of_measurement

      t.integer :charge_factory_id

      t.timestamps null: false
    end
  end
end
