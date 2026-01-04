class CreatePracticeChallenges < ActiveRecord::Migration[8.0]
  def change
    create_table :practice_challenges do |t|
      t.jsonb :title
      t.jsonb :description
      t.string :category
      t.string :difficulty
      t.jsonb :starter_code
      t.jsonb :solution_hints
      t.jsonb :evaluation_criteria
      t.boolean :active

      t.timestamps
    end
  end
end
