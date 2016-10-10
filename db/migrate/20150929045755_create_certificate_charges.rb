class CreateCertificateCharges < ActiveRecord::Migration
  def change
    create_table :certificate_charges do |t|
      t.timestamps null: false
    end
  end
end
