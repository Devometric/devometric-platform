class CreateChatSessions < ActiveRecord::Migration[8.0]
  def change
    create_table :chat_sessions do |t|
      t.references :company, null: false, foreign_key: true
      t.string :session_token, null: false
      t.string :external_user_id
      t.jsonb :user_context, default: {}
      t.string :locale, default: 'en'
      t.datetime :started_at
      t.datetime :ended_at

      t.timestamps
    end
    add_index :chat_sessions, :session_token, unique: true
    add_index :chat_sessions, [:company_id, :external_user_id]
    add_index :chat_sessions, :started_at
  end
end
