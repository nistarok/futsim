class CreateLineups < ActiveRecord::Migration[8.0]
  def change
    create_table :lineups do |t|
      t.string :name
      t.string :formation
      t.references :club, null: false, foreign_key: true
      t.date :match_date
      t.boolean :active

      t.timestamps
    end
  end
end
