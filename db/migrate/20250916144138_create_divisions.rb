class CreateDivisions < ActiveRecord::Migration[8.0]
  def change
    create_table :divisions do |t|
      t.string :name
      t.integer :level
      t.text :description

      t.timestamps
    end
  end
end
