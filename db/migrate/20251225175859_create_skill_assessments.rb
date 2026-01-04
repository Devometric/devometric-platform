class CreateSkillAssessments < ActiveRecord::Migration[8.0]
  def change
    create_table :skill_assessments do |t|
      t.references :user, null: false, foreign_key: true
      t.string :skill_category
      t.string :level
      t.jsonb :details
      t.datetime :assessed_at

      t.timestamps
    end
  end
end
