class CreateParticipants < ActiveRecord::Migration
  def change
#    create_table :participants do |t|
#      t.string :providerid
#      t.timestamps null: false
#    end
#    execute "ALTER TABLE participants ALTER COLUMN providerid TYPE varchar(10);"
    execute "CREATE TABLE participants (providerid VARCHAR(10) NOT NULL PRIMARY KEY);"
  end
end
