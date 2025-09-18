class AddAvailableToClubs < ActiveRecord::Migration[8.0]
  def change
    add_column :clubs, :available, :boolean
  end
end
