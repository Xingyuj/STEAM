class AddImportedInvoiceIdToGeneratedOne < ActiveRecord::Migration
  def change
  change_table :generated_invoices do |t|
    t.integer :imported_invoice_id
    end
  end
end
