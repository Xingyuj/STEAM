class AddRetailPlanIdToDailyUsageCharge < ActiveRecord::Migration
  def change
    add_column :retail_plans, :daily_usage_charge_id, :integer
    add_column :daily_usage_charges, :retail_plan_id, :integer
    add_column :retail_plans, :charge_factory_id, :integer
  end
end
