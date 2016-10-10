class RemoveUnwantedFieldsFromRetailPlan < ActiveRecord::Migration
  def change
    remove_column :retail_plans, :retail_account_id, :integer
    remove_column :retail_plans, :created, :date
  end
end
