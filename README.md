# Paticipating

## User

**Gem:** [devise 3.5.1](https://github.com/plataformatec/devise)

### Install devise

	rails g devise:install
	
### Generate user model
	
	rails g devise User
	
### Add username field
	
1. **Add name in the migratation:**
	
	```ruby
	t.string :name
	```

2. **Permit name parameter:**

    ```
	class Users::RegistrationsController < Devise::RegistrationsController
	before_filter :configure_sign_up_params, only: [:create]
	before_filter :configure_account_update_params, only: [:update]
	#
	# If you have extra params to permit, append them to the sanitizer.
	def configure_sign_up_params
		devise_parameter_sanitizer.for(:sign_up) << :name
	end
	#
	# If you have extra params to permit, append them to the sanitizer.
	def configure_account_update_params
		devise_parameter_sanitizer.for(:account_update) << :name
	end
	```
	
3. **Configuring routes:**

	```ruby
	devise_for :users, controllers: { registrations: "users/registrations" }
	```
	
### Attributes

```
    t.string   "name"
    t.string   "email",                  default: "", null: false
    t.string   "encrypted_password",     default: "", null: false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",          default: 0,  null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.inet     "current_sign_in_ip"
    t.inet     "last_sign_in_ip"
    t.datetime "created_at",                          null: false
    t.datetime "updated_at",                          null: false
```

### Controller

Create user_controller.rb file:

	def upload_nem12
	def import_nem12
	
### View

Create upload_nem12.html.erb file:

```
<%= form_tag users_import_path, multipart: true do %>
    <%= file_field_tag 'files[]', multiple: true %>
    <%= submit_tag "Import" %>
<% end %>
```

## FtpServer

**Gem:** [rufus-scheduler 3.1.3](https://github.com/jmettraux/rufus-scheduler)

### FTP


```ruby
# app/models/ftp_server.rb

ftp = Net::FTP.new
ftp.connect(host,21)
ftp.login(username,password)
ftp.passive = true
ftp.chdir("/directory")
filenames = ftp.nlst()
filenames.each do |remote_file| #Loop through each element of the array
	local_file = File.join("home/#{user}/#{host}/#{current_time}", filename)
	ftp.getbinaryfile(remote_file,local_file) #Get the file
end
ftp.close
```

### Scheduler

Create scheduler.rb file:

```ruby
# config/initializers/scheduler.rb

require 'rufus-scheduler'

# Let's use the rufus-scheduler singleton
#
scheduler = Rufus::Scheduler.singleton

# Stupid recurrent task...
#
scheduler.every '1d' do
	FtpServer.download
end
```
### Attributes

```
    t.string   "name"
    t.string   "server"
    t.string   "username"
    t.string   "password"
    t.date     "last_poll"
    t.date     "next_poll"
    t.integer  "poll_unit"
    t.integer  "poll_value"
    t.integer  "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
```

### Model

	def self.download
	

## Site

Create by scaffold.

### Attributes

```
    t.string   "name"
    t.string   "address1"
    t.string   "address2"
    t.integer  "user_id"
    t.datetime "created"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
```

## BillingSite

Create by scaffold.

```
    t.string   "name"
    t.integer  "site_id"
    t.datetime "created"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
```

## Test

### Test Case for Download FTP

* Add a useful FTP server with file "test.csv"
* Runing the rails server
* The system will automatically run the download function
* The 'home/username/ftp_domain/unixtime/" directiory will be created.
* the file "test.csv" will successfully download and store in the specific directory

### Test Case for upload file

* Select the file from local computer
* Submit the file by clicking the "Submit" button
* The file will successfully be uploaded on the server

