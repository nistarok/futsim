class CreateSeasons < ActiveRecord::Migration[8.0]
  def change
    create_table :seasons do |t|
      t.string :name
      t.integer :year
      t.references :division, null: false, foreign_key: true
      t.boolean :active

      t.timestamps
    end
  end
end
