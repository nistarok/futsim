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

ActiveRecord::Schema[8.0].define(version: 2025_09_17_224323) do
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
    t.bigint "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "room_id", null: false
    t.boolean "available"
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

  create_table "lineup_players", force: :cascade do |t|
    t.bigint "lineup_id", null: false
    t.bigint "player_id", null: false
    t.string "position"
    t.boolean "starting"
    t.integer "substitution_minute"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["lineup_id"], name: "index_lineup_players_on_lineup_id"
    t.index ["player_id"], name: "index_lineup_players_on_player_id"
  end

  create_table "lineups", force: :cascade do |t|
    t.string "name"
    t.string "formation"
    t.bigint "club_id", null: false
    t.date "match_date"
    t.boolean "active"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["club_id"], name: "index_lineups_on_club_id"
  end

  create_table "matches", force: :cascade do |t|
    t.bigint "round_id", null: false
    t.bigint "home_club_id", null: false
    t.bigint "away_club_id", null: false
    t.integer "home_score"
    t.integer "away_score"
    t.string "status"
    t.datetime "match_date"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "match_events"
    t.index ["away_club_id"], name: "index_matches_on_away_club_id"
    t.index ["home_club_id"], name: "index_matches_on_home_club_id"
    t.index ["round_id"], name: "index_matches_on_round_id"
  end

  create_table "move_approvals", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "round_id", null: false
    t.string "status"
    t.datetime "approved_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["round_id"], name: "index_move_approvals_on_round_id"
    t.index ["user_id", "round_id"], name: "index_move_approvals_on_user_id_and_round_id", unique: true
    t.index ["user_id"], name: "index_move_approvals_on_user_id"
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

  create_table "rounds", force: :cascade do |t|
    t.bigint "room_id", null: false
    t.integer "number"
    t.string "status"
    t.date "start_date"
    t.date "end_date"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["room_id"], name: "index_rounds_on_room_id"
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
    t.string "role", default: "player", null: false
    t.index ["role"], name: "index_users_on_role"
  end

  add_foreign_key "clubs", "divisions"
  add_foreign_key "clubs", "rooms"
  add_foreign_key "clubs", "users"
  add_foreign_key "lineup_players", "lineups"
  add_foreign_key "lineup_players", "players"
  add_foreign_key "lineups", "clubs"
  add_foreign_key "matches", "clubs", column: "away_club_id"
  add_foreign_key "matches", "clubs", column: "home_club_id"
  add_foreign_key "matches", "rounds"
  add_foreign_key "move_approvals", "rounds"
  add_foreign_key "move_approvals", "users"
  add_foreign_key "players", "clubs"
  add_foreign_key "rooms", "users"
  add_foreign_key "rounds", "rooms"
  add_foreign_key "seasons", "divisions"
  add_foreign_key "seasons", "rooms"
end
