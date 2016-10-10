class CreatePredictedInvoices < ActiveRecord::Migration
  def change
    create_table :predicted_invoices do |t|

      t.timestamps null: false
    end
  end
end
