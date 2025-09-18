class CreateRounds < ActiveRecord::Migration[8.0]
  def change
    create_table :rounds do |t|
      t.references :room, null: false, foreign_key: true
      t.integer :number
      t.string :status
      t.date :start_date
      t.date :end_date

      t.timestamps
    end
  end
end
