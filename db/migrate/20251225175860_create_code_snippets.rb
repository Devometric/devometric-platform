class CreateCodeSnippets < ActiveRecord::Migration[8.0]
  def change
    create_table :code_snippets do |t|
      t.references :user, null: false, foreign_key: true
      t.references :coaching_session, null: false, foreign_key: true
      t.string :title
      t.text :original_code
      t.text :improved_code
      t.text :ai_explanation
      t.string :language
      t.jsonb :tags

      t.timestamps
    end
  end
end
