class CreateRooms < ActiveRecord::Migration[8.0]
  def change
    create_table :rooms do |t|
      t.string :name, null: false
      t.boolean :is_multiplayer, null: false, default: false
      t.integer :max_players, null: false, default: 1
      t.integer :current_players, null: false, default: 0
      t.references :user, null: false, foreign_key: true
      t.text :description
      t.string :status, null: false, default: 'waiting'

      t.timestamps
    end

    add_index :rooms, [:user_id, :is_multiplayer]
  end
end
