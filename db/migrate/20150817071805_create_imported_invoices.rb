class CreateImportedInvoices < ActiveRecord::Migration
  def change
    create_table :imported_invoices do |t|
      t.string :file

      t.timestamps null: false
    end
  end
end
