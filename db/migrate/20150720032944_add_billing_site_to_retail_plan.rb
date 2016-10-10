class AddBillingSiteToRetailPlan < ActiveRecord::Migration
  def up
  	add_column :retail_plans, :billing_site_id, :integer
  end

  def down
  	remove_column :retail_plans, :billing_site_id
  end
end
