# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20151007100914) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "billing_sites", force: :cascade do |t|
    t.string   "name"
    t.integer  "site_id"
    t.datetime "created"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "capacity_charges", force: :cascade do |t|
    t.string   "period"
    t.datetime "created_at",          null: false
    t.datetime "updated_at",          null: false
    t.string   "unit_of_measurement"
  end

  create_table "certificate_charges", force: :cascade do |t|
    t.datetime "created_at",          null: false
    t.datetime "updated_at",          null: false
    t.string   "unit_of_measurement"
  end

  create_table "charge_factories", force: :cascade do |t|
    t.string   "name"
    t.decimal  "rate",           precision: 10, scale: 5
    t.integer  "retail_plan_id"
    t.datetime "created_at",                              null: false
    t.datetime "updated_at",                              null: false
    t.integer  "actable_id"
    t.string   "actable_type"
  end

  create_table "concrete_charges", force: :cascade do |t|
    t.integer  "invoice_id"
    t.decimal  "amount"
    t.string   "charge_attributes"
    t.datetime "created_at",        null: false
    t.datetime "updated_at",        null: false
    t.integer  "charge_factory_id"
    t.string   "invoice_type"
  end

  create_table "daily_usage_charges", force: :cascade do |t|
    t.time     "start_time"
    t.time     "end_time"
    t.string   "unit_of_measurement"
    t.datetime "created_at",          null: false
    t.datetime "updated_at",          null: false
  end

  create_table "ftp_servers", force: :cascade do |t|
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
  end

  create_table "generated_invoices", force: :cascade do |t|
    t.datetime "created_at",          null: false
    t.datetime "updated_at",          null: false
    t.integer  "imported_invoice_id"
  end

  create_table "global_usage_charges", force: :cascade do |t|
    t.string   "unit_of_measurement"
    t.datetime "created_at",          null: false
    t.datetime "updated_at",          null: false
  end

  create_table "imported_invoices", force: :cascade do |t|
    t.string   "file"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "invoices", force: :cascade do |t|
    t.date     "start_date"
    t.date     "end_date"
    t.date     "issue_date"
    t.float    "distribution_loss_factor"
    t.float    "marginal_loss_factor"
    t.decimal  "total"
    t.integer  "retail_plan_id"
    t.datetime "created_at",               null: false
    t.datetime "updated_at",               null: false
    t.integer  "actable_id"
    t.string   "actable_type"
  end

  create_table "linear_regression_predictors", force: :cascade do |t|
    t.decimal  "a"
    t.decimal  "b"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "meter_aggregations", force: :cascade do |t|
    t.integer "meter_id",                                     null: false
    t.string  "register",            limit: 10,               null: false
    t.date    "date",                                         null: false
    t.time    "start_time",                                   null: false
    t.time    "end_time",                                     null: false
    t.string  "unit_of_measurement", limit: 5,                null: false
    t.float   "usage",                                        null: false
    t.string  "source",              limit: 1,  default: "r"
    t.float   "maximum_demand"
  end

  add_index "meter_aggregations", ["date"], name: "index_meter_aggregations_on_date", using: :btree
  add_index "meter_aggregations", ["end_time"], name: "index_meter_aggregations_on_end_time", using: :btree
  add_index "meter_aggregations", ["meter_id"], name: "index_meter_aggregations_on_meter_id", using: :btree
  add_index "meter_aggregations", ["register"], name: "index_meter_aggregations_on_register", using: :btree
  add_index "meter_aggregations", ["start_time"], name: "index_meter_aggregations_on_start_time", using: :btree

  create_table "meter_predictors", force: :cascade do |t|
    t.integer  "meter_id",        null: false
    t.time     "start_time",      null: false
    t.time     "end_time",        null: false
    t.date     "calculated_date", null: false
    t.datetime "created_at",      null: false
    t.datetime "updated_at",      null: false
    t.integer  "actable_id"
    t.string   "actable_type"
  end

  add_index "meter_predictors", ["end_time"], name: "index_meter_predictors_on_end_time", using: :btree
  add_index "meter_predictors", ["meter_id"], name: "index_meter_predictors_on_meter_id", using: :btree
  add_index "meter_predictors", ["start_time"], name: "index_meter_predictors_on_start_time", using: :btree

  create_table "meter_records", force: :cascade do |t|
    t.integer "meter_id"
    t.string  "register",            limit: 10,              null: false
    t.date    "date",                                        null: false
    t.integer "interval",                       default: 30
    t.string  "unit_of_measurement", limit: 5,               null: false
    t.float   "usage",                                       null: false, array: true
  end

  add_index "meter_records", ["date"], name: "index_meter_records_on_date", using: :btree
  add_index "meter_records", ["meter_id", "register", "date"], name: "composite", unique: true, using: :btree
  add_index "meter_records", ["meter_id"], name: "index_meter_records_on_meter_id", using: :btree
  add_index "meter_records", ["register"], name: "index_meter_records_on_register", using: :btree

  create_table "metering_charges", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "meters", force: :cascade do |t|
    t.string   "serial",          limit: 12, null: false
    t.string   "nmi",             limit: 10, null: false
    t.integer  "billing_site_id"
    t.datetime "created_at",                 null: false
    t.datetime "updated_at",                 null: false
  end

  create_table "predicted_invoices", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "retail_plans", force: :cascade do |t|
    t.string   "name"
    t.date     "start_date"
    t.date     "end_date"
    t.date     "expected_expiry_date"
    t.float    "discount"
    t.datetime "created_at",           null: false
    t.datetime "updated_at",           null: false
    t.integer  "billing_site_id"
    t.integer  "retailer_id"
    t.string   "billing_interval"
  end

  create_table "retailers", force: :cascade do |t|
    t.string   "retailer_name"
    t.string   "retailer_address"
    t.datetime "created_at",       null: false
    t.datetime "updated_at",       null: false
  end

  create_table "sites", force: :cascade do |t|
    t.string   "name"
    t.string   "address1"
    t.string   "address2"
    t.integer  "user_id"
    t.datetime "created"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "supply_charges", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "users", force: :cascade do |t|
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
  end

  add_index "users", ["email"], name: "index_users_on_email", unique: true, using: :btree
  add_index "users", ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true, using: :btree

end
