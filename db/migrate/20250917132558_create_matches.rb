class CreateMatches < ActiveRecord::Migration[8.0]
  def change
    create_table :matches do |t|
      t.references :round, null: false, foreign_key: true
      t.references :home_club, null: false, foreign_key: { to_table: :clubs }
      t.references :away_club, null: false, foreign_key: { to_table: :clubs }
      t.integer :home_score
      t.integer :away_score
      t.string :status
      t.datetime :match_date

      t.timestamps
    end
  end
end
