class AddMatchEventsToMatches < ActiveRecord::Migration[8.0]
  def change
    add_column :matches, :match_events, :text
  end
end
