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
    t.bigint "campaign_id", null: false
    t.string "contact_type", null: false
    t.bigint "contact_id", null: false
    t.datetime "last_sent_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["campaign_id"], name: "index_heya_campaign_memberships_on_campaign_id"
    t.index ["contact_id", "campaign_id"], name: "index_heya_campaign_memberships_on_contact_id_and_campaign_id", unique: true
    t.index ["contact_type", "contact_id"], name: "index_heya_campaign_memberships_on_contact_type_and_contact_id"
  end

  create_table "heya_campaigns", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "heya_message_receipts", force: :cascade do |t|
    t.bigint "message_id", null: false
    t.string "contact_type", null: false
    t.bigint "contact_id", null: false
    t.datetime "sent_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["contact_type", "contact_id"], name: "index_heya_message_receipts_on_contact_type_and_contact_id"
    t.index ["message_id", "contact_id"], name: "index_heya_message_receipts_on_message_id_and_contact_id", unique: true
    t.index ["message_id"], name: "index_heya_message_receipts_on_message_id"
  end

  create_table "heya_messages", force: :cascade do |t|
    t.bigint "campaign_id"
    t.string "name"
    t.integer "position", null: false
    t.integer "wait", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["campaign_id", "position"], name: "index_heya_messages_on_campaign_id_and_position"
    t.index ["campaign_id"], name: "index_heya_messages_on_campaign_id"
  end

  add_foreign_key "heya_campaign_memberships", "heya_campaigns", column: "campaign_id"
  add_foreign_key "heya_message_receipts", "heya_messages", column: "message_id"
  add_foreign_key "heya_messages", "heya_campaigns", column: "campaign_id"
end
