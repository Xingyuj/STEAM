class CreateFtpServers < ActiveRecord::Migration
  def change
    create_table :ftp_servers do |t|
      t.string :name
      t.string :server
      t.string :username
      t.string :password
      t.date :last_poll
      t.date :next_poll
      t.integer :poll_unit
      t.integer :poll_value
      t.integer :user_id

      t.timestamps null: false
    end
  end
end
