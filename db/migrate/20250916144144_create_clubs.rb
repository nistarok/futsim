class CreateClubs < ActiveRecord::Migration[8.0]
  def change
    create_table :clubs do |t|
      t.string :name
      t.string :city
      t.integer :founded_year
      t.string :stadium_name
      t.integer :stadium_capacity
      t.decimal :budget
      t.references :division, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end
  end
end
