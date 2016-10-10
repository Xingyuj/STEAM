class CreateRetailPlans < ActiveRecord::Migration
  def change
    create_table :retail_plans do |t|
    	t.string :name
      t.date :created
    	t.date :start_date
    	t.date :end_date
    	t.date :expected_expiry_date
    	t.float :discount



      t.timestamps null: false
    end


  end
end
