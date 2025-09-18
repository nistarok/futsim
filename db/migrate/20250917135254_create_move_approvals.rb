class CreateMoveApprovals < ActiveRecord::Migration[8.0]
  def change
    create_table :move_approvals do |t|
      t.references :user, null: false, foreign_key: true
      t.references :round, null: false, foreign_key: true
      t.string :status
      t.datetime :approved_at

      t.timestamps
    end

    add_index :move_approvals, [:user_id, :round_id], unique: true
  end
end
