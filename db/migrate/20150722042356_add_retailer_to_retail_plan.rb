class AddRetailerToRetailPlan < ActiveRecord::Migration
  def change
    add_column :retail_plans, :retailer_id, :integer
  end

end
