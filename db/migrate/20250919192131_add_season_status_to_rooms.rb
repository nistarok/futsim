class AddSeasonStatusToRooms < ActiveRecord::Migration[8.0]
  def change
    add_column :rooms, :season_status, :string, default: 'pending'
    add_index :rooms, :season_status
  end
end
