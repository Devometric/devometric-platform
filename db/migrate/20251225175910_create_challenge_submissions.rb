class CreateChallengeSubmissions < ActiveRecord::Migration[8.0]
  def change
    create_table :challenge_submissions do |t|
      t.references :user, null: false, foreign_key: true
      t.references :practice_challenge, null: false, foreign_key: true
      t.references :coaching_session, null: false, foreign_key: true
      t.text :submitted_code
      t.text :prompt_used
      t.jsonb :evaluation
      t.integer :score

      t.timestamps
    end
  end
end
