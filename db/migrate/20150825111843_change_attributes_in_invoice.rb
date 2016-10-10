class ChangeAttributesInInvoice < ActiveRecord::Migration
  def change
  	rename_column :invoices, :invoiced_total, :total
  	remove_column :invoices, :generated_total, :decimal
  	remove_column :invoices, :total_loss_factor, :float
  	remove_column :invoices, :file, :string
  end
end
