class ChangeAttributesInConcreteCharge < ActiveRecord::Migration
  def change
  	remove_column :concrete_charges, :invoiced_amount, :decimal
  	rename_column :concrete_charges, :generated_amount, :amount
  	add_column :concrete_charges, :invoice_type, :string
  end
end
