class MakeInvoiceActable < ActiveRecord::Migration
  def change
    change_table :invoices do |t|
      t.actable
    end

  end
end
