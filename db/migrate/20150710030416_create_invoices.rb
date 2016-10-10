class CreateInvoices < ActiveRecord::Migration
  def change
    create_table :invoices do |t|
    	t.string :file
    	t.date :start_date, :end_date, :issue_date

    	t.float :distribution_loss_factor, :marginal_loss_factor, :total_loss_factor

    	t.decimal :invoiced_total, :generated_total
    	t.integer :retail_plan_id

      t.timestamps null: false
    end
  end
end
