class AddFieldsToSeasons < ActiveRecord::Migration[8.0]
  def change
    add_column :seasons, :start_date, :date
    add_column :seasons, :end_date, :date
    add_column :seasons, :status, :string, default: 'preparation'
    add_reference :seasons, :room, null: false, foreign_key: true
    remove_column :seasons, :active, :boolean
  end
end
