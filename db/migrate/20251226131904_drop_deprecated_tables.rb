class DropDeprecatedTables < ActiveRecord::Migration[8.0]
  def change
    # Drop tables in correct order (respecting foreign keys)
    drop_table :challenge_submissions, if_exists: true
    drop_table :user_progresses, if_exists: true
    drop_table :code_snippets, if_exists: true
    drop_table :coaching_sessions, if_exists: true
    drop_table :lessons, if_exists: true
    drop_table :learning_paths, if_exists: true
    drop_table :skill_assessments, if_exists: true
    drop_table :practice_challenges, if_exists: true
  end
end
