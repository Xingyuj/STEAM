class CreateMeters < ActiveRecord::Migration
  def change
    execute "CREATE TABLE meters (nmi CHAR(10) NOT NULL PRIMARY KEY, serial VARCHAR(12), providerID VARCHAR(10));"
    add_index :meters, :nmi, unique: false
    add_index :meters, :serial, unique: true
  end
end
