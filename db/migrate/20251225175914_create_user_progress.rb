class CreateUserProgress < ActiveRecord::Migration[8.0]
  def change
    create_table :user_progresses do |t|
      t.references :user, null: false, foreign_key: true
      t.references :learning_path, null: false, foreign_key: true
      t.references :lesson, null: false, foreign_key: true
      t.string :status
      t.datetime :completed_at
      t.integer :score
      t.text :notes

      t.timestamps
    end
  end
end
