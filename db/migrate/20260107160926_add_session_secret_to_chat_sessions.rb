class AddSessionSecretToChatSessions < ActiveRecord::Migration[8.0]
  def change
    add_column :chat_sessions, :session_secret, :string
    add_index :chat_sessions, :session_secret
  end
end
