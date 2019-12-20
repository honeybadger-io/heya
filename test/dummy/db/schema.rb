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

ActiveRecord::Schema.define(version: 2019_06_13_183430) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "contacts", force: :cascade do |t|
    t.string "email"
    t.jsonb "traits"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "heya_campaign_memberships", force: :cascade do |t|
    t.string "user_type", null: false
    t.bigint "user_id", null: false
    t.string "campaign_gid", null: false
    t.boolean "concurrent", default: false, null: false
    t.datetime "last_sent_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_type", "user_id", "campaign_gid"], name: "user_campaign_idx", unique: true
  end

  create_table "heya_campaign_receipts", force: :cascade do |t|
    t.string "user_type", null: false
    t.bigint "user_id", null: false
    t.string "step_gid", null: false
    t.datetime "sent_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_type", "user_id", "step_gid"], name: "user_step_idx", unique: true
  end

end
