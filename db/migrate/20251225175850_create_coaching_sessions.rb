class CreateCoachingSessions < ActiveRecord::Migration[8.0]
  def change
    create_table :coaching_sessions do |t|
      t.references :user, null: false, foreign_key: true
      t.references :learning_path, foreign_key: true  # Optional for freeform sessions
      t.references :lesson, foreign_key: true          # Optional for freeform sessions
      t.string :session_type, null: false, default: "freeform"  # guided, freeform, code_review, debugging, practice
      t.string :title
      t.string :programming_language
      t.text :code_context
      t.text :summary
      t.datetime :started_at
      t.datetime :ended_at

      t.timestamps
    end
    add_index :coaching_sessions, :session_type
    add_index :coaching_sessions, :programming_language
    add_index :coaching_sessions, [:user_id, :created_at]
  end
end
