class CreateRetailers < ActiveRecord::Migration
  def change
    create_table :retailers do |t|
      t.string :retailer_name, :retailer_address

      t.timestamps null: false
    end
  end
end
