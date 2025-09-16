# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 2025_09_16_165720) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "clubs", force: :cascade do |t|
    t.string "name"
    t.string "city"
    t.integer "founded_year"
    t.string "stadium_name"
    t.integer "stadium_capacity"
    t.decimal "budget"
    t.bigint "division_id", null: false
    t.bigint "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "room_id", null: false
    t.index ["division_id"], name: "index_clubs_on_division_id"
    t.index ["room_id"], name: "index_clubs_on_room_id"
    t.index ["user_id"], name: "index_clubs_on_user_id"
  end

  create_table "divisions", force: :cascade do |t|
    t.string "name"
    t.integer "level"
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "players", force: :cascade do |t|
    t.string "name"
    t.string "nationality"
    t.string "position"
    t.integer "age"
    t.integer "strength"
    t.integer "stamina"
    t.integer "speed"
    t.integer "attack"
    t.integer "defense"
    t.integer "passing"
    t.integer "overall"
    t.bigint "club_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.decimal "market_value", precision: 12, scale: 2, default: "0.0", null: false
    t.decimal "salary", precision: 10, scale: 2, default: "0.0", null: false
    t.index ["club_id"], name: "index_players_on_club_id"
  end

  create_table "rooms", force: :cascade do |t|
    t.string "name"
    t.boolean "is_multiplayer"
    t.integer "max_players"
    t.integer "current_players"
    t.bigint "user_id", null: false
    t.text "description"
    t.string "status"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_rooms_on_user_id"
  end

  create_table "seasons", force: :cascade do |t|
    t.string "name"
    t.integer "year"
    t.bigint "division_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.date "start_date"
    t.date "end_date"
    t.string "status", default: "preparation"
    t.bigint "room_id", null: false
    t.index ["division_id"], name: "index_seasons_on_division_id"
    t.index ["room_id"], name: "index_seasons_on_room_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email"
    t.string "provider"
    t.string "uid"
    t.string "name"
    t.string "oauth_token"
    t.datetime "oauth_expires_at"
    t.string "invitation_token"
    t.datetime "invitation_created_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_foreign_key "clubs", "divisions"
  add_foreign_key "clubs", "rooms"
  add_foreign_key "clubs", "users"
  add_foreign_key "players", "clubs"
  add_foreign_key "rooms", "users"
  add_foreign_key "seasons", "divisions"
  add_foreign_key "seasons", "rooms"
end
