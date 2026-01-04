class CreateUsageLogs < ActiveRecord::Migration[8.0]
  def change
    create_table :usage_logs do |t|
      t.references :company, null: false, foreign_key: true
      t.date :date, null: false
      t.integer :sessions_count, default: 0, null: false
      t.integer :messages_count, default: 0, null: false
      t.integer :unique_users_count, default: 0, null: false
      t.integer :tokens_used, default: 0, null: false

      t.timestamps
    end
    add_index :usage_logs, [:company_id, :date], unique: true
    add_index :usage_logs, :date
  end
end
