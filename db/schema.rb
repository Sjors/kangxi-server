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

ActiveRecord::Schema.define(version: 20140402134021) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "characters", force: true do |t|
    t.string   "simplified"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "level"
    t.boolean  "demo",       default: false
  end

  create_table "characters_radicals", force: true do |t|
    t.integer  "character_id"
    t.integer  "radical_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "characters_radicals", ["character_id"], name: "index_characters_radicals_on_character_id", using: :btree
  add_index "characters_radicals", ["radical_id"], name: "index_characters_radicals_on_radical_id", using: :btree

  create_table "characters_words", force: true do |t|
    t.integer "character_id"
    t.integer "word_id"
  end

  add_index "characters_words", ["character_id"], name: "index_characters_words_on_character_id", using: :btree
  add_index "characters_words", ["word_id"], name: "index_characters_words_on_word_id", using: :btree

  create_table "radicals", force: true do |t|
    t.integer  "position"
    t.string   "simplified"
    t.boolean  "variant",        default: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "note"
    t.integer  "radicals",       default: [],    array: true
    t.boolean  "ambiguous",      default: false
    t.integer  "frequency",      default: 0
    t.integer  "synonyms",       default: [],    array: true
    t.boolean  "is_synonym",     default: false
    t.integer  "do_not_confuse", default: [],    array: true
    t.boolean  "demo",           default: false
  end

  create_table "users", force: true do |t|
    t.string   "email",                  default: "",            null: false
    t.string   "encrypted_password",     default: "",            null: false
    t.string   "type",                   default: "DefaultUser"
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",          default: 0
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "users", ["email"], name: "index_users_on_email", unique: true, using: :btree
  add_index "users", ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true, using: :btree

  create_table "words", force: true do |t|
    t.string   "simplified"
    t.string   "english",    default: [], array: true
    t.datetime "created_at"
    t.datetime "updated_at"
  end

end
