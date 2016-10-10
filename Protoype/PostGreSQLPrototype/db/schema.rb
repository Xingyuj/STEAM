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

ActiveRecord::Schema.define(version: 20150508072459) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "billings", force: :cascade do |t|
    t.integer "start_time_hour"
    t.integer "end_time_hour"
  end

  create_table "meter_aggregations", id: false, force: :cascade do |t|
    t.string  "meter_serial", limit: 12, null: false
    t.date    "date",                    null: false
    t.integer "start_time"
    t.integer "end_time"
    t.float   "aggregation"
  end

  add_index "meter_aggregations", ["date"], name: "index_meter_aggregations_on_date", using: :btree
  add_index "meter_aggregations", ["end_time"], name: "index_meter_aggregations_on_end_time", using: :btree
  add_index "meter_aggregations", ["meter_serial"], name: "index_meter_aggregations_on_meter_serial", using: :btree
  add_index "meter_aggregations", ["start_time"], name: "index_meter_aggregations_on_start_time", using: :btree

  create_table "meter_records", id: false, force: :cascade do |t|
    t.string  "meter_serial",   limit: 12
    t.date    "date"
    t.float   "values",                                 array: true
    t.integer "meter_interval",            default: 30
  end

  add_index "meter_records", ["date"], name: "index_meter_records_on_date", using: :btree
  add_index "meter_records", ["meter_serial"], name: "index_meter_records_on_meter_serial", using: :btree

  create_table "meters", primary_key: "nmi", force: :cascade do |t|
    t.string "serial",     limit: 12
    t.string "providerid", limit: 10
  end

  add_index "meters", ["nmi"], name: "index_meters_on_nmi", using: :btree
  add_index "meters", ["serial"], name: "index_meters_on_serial", unique: true, using: :btree

  create_table "participants", primary_key: "providerid", force: :cascade do |t|
  end

end
