class AddMarketValueAndSalaryToPlayers < ActiveRecord::Migration[8.0]
  def change
    add_column :players, :market_value, :decimal, precision: 12, scale: 2, null: false, default: 0
    add_column :players, :salary, :decimal, precision: 10, scale: 2, null: false, default: 0
  end
end
