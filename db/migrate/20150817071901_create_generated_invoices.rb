class CreateGeneratedInvoices < ActiveRecord::Migration
  def change
    create_table :generated_invoices do |t|

      t.timestamps null: false
    end
  end
end
