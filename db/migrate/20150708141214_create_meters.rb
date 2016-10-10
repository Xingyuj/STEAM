class CreateMeters < ActiveRecord::Migration
  def change
    create_table :meters do |t|
      t.column :serial, "varchar(12)", :null => false
      t.column :nmi, "char(10)", :null => false
      t.integer :billing_site_id
      t.timestamps null: false
    end
  end
end
