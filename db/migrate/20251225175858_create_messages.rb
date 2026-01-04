class CreateMessages < ActiveRecord::Migration[8.0]
  def change
    create_table :messages do |t|
      t.references :coaching_session, null: false, foreign_key: true
      t.string :role
      t.text :content
      t.jsonb :code_blocks
      t.integer :tokens_used

      t.timestamps
    end
  end
end
