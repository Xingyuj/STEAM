class RemoveFk < ActiveRecord::Migration
  def change
  	remove_column :daily_usage_charges, :charge_factory_id, :integer

		remove_column :daily_usage_charges, :retail_plan_id, :integer

		remove_column :retail_plans, :daily_usage_charge_id, :integer
		remove_column :retail_plans, :charge_factory_id, :integer

  	remove_column :global_usage_charges, :charge_factory_id, :integer
  	remove_column :metering_charges, :charge_factory_id, :integer
  	remove_column :supply_charges, :charge_factory_id, :integer
  end
end
