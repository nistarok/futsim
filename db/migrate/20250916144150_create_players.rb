class CreatePlayers < ActiveRecord::Migration[8.0]
  def change
    create_table :players do |t|
      t.string :name
      t.string :nationality
      t.string :position
      t.integer :age
      t.integer :strength
      t.integer :stamina
      t.integer :speed
      t.integer :attack
      t.integer :defense
      t.integer :passing
      t.integer :overall
      t.references :club, null: false, foreign_key: true

      t.timestamps
    end
  end
end
