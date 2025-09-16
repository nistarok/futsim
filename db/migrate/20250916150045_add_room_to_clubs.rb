class AddRoomToClubs < ActiveRecord::Migration[8.0]
  def change
    add_reference :clubs, :room, null: false, foreign_key: true
  end
end
