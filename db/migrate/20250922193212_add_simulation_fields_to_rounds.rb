class AddSimulationFieldsToRounds < ActiveRecord::Migration[8.0]
  def change
    add_column :rounds, :simulation_status, :string
    add_column :rounds, :simulation_started_at, :datetime
    add_column :rounds, :simulation_completed_at, :datetime
    add_column :rounds, :current_minute, :integer
  end
end
