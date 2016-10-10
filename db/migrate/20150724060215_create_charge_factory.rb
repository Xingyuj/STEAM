class CreateChargeFactory < ActiveRecord::Migration
  def change
    create_table :charge_factories do |t|

      t.string :name
      t.decimal :rate, precision: 10, scale: 5

      t.integer :retail_plan_id

      t.timestamps null: false

    end
  end
end
