class CreateSites < ActiveRecord::Migration
  def change
    create_table :sites do |t|
      t.string :name
      t.string :address1
      t.string :address2
      t.integer :user_id
      t.datetime :created

      t.timestamps null: false
    end
  end
end
