class CreateConcreteCharges < ActiveRecord::Migration
  def change
    create_table :concrete_charges do |t|

      # belongs_to :invoice
      t.integer :invoice_id

      t.decimal :invoiced_amount
      t.decimal :generated_amount

      # not sure what this is used for yet
      t.string :charge_attributes

      t.timestamps null: false
    end
  end
end
