class AddActableToChargeFactory < ActiveRecord::Migration
  def change
  	change_table :charge_factories do |t|
  		t.actable
	end
  end
end
