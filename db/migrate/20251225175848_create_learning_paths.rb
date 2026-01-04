class CreateLearningPaths < ActiveRecord::Migration[8.0]
  def change
    create_table :learning_paths do |t|
      t.string :slug, null: false
      t.jsonb :title, default: {}
      t.jsonb :description, default: {}
      t.string :icon
      t.string :difficulty, default: "beginner"
      t.integer :position
      t.boolean :active, default: true

      t.timestamps
    end
    add_index :learning_paths, :slug, unique: true
    add_index :learning_paths, :active
  end
end
