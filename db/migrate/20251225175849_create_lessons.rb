class CreateLessons < ActiveRecord::Migration[8.0]
  def change
    create_table :lessons do |t|
      t.references :learning_path, null: false, foreign_key: true
      t.string :slug
      t.jsonb :title
      t.jsonb :content
      t.jsonb :objectives
      t.jsonb :exercises
      t.integer :position
      t.integer :estimated_minutes
      t.boolean :active

      t.timestamps
    end
  end
end
