class AddRetailAccountIdToRetailPlan < ActiveRecord::Migration
  def change
    add_column :retail_plans, :retail_account_id, :integer
    add_column :retail_plans, :billing_interval, :string
  end
end
