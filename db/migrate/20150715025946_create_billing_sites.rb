class CreateBillingSites < ActiveRecord::Migration
  def change
    create_table :billing_sites do |t|
      t.string :name
      t.integer :site_id
      t.datetime :created

      t.timestamps null: false
    end
  end
end
