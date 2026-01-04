class UpdateMessagesForChatSessions < ActiveRecord::Migration[8.0]
  def change
    # Add chat_session reference
    add_reference :messages, :chat_session, foreign_key: true

    # Remove coaching_session reference
    remove_foreign_key :messages, :coaching_sessions
    remove_index :messages, :coaching_session_id
    remove_column :messages, :coaching_session_id, :bigint
  end
end
