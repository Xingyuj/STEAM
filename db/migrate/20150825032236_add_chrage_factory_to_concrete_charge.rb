class AddChrageFactoryToConcreteCharge < ActiveRecord::Migration
  def change
  	change_table :concrete_charges do |t|
		t.integer :charge_factory_id
	end
  end
end
