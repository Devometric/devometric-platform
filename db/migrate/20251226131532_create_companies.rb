class CreateCompanies < ActiveRecord::Migration[8.0]
  def change
    create_table :companies do |t|
      t.string :name, null: false
      t.string :slug, null: false
      t.string :embed_key, null: false
      t.text :system_prompt
      t.text :policies
      t.text :coding_standards
      t.text :work_culture
      t.jsonb :tech_stack, default: []
      t.jsonb :settings, default: {}
      t.boolean :active, default: true, null: false

      t.timestamps
    end
    add_index :companies, :slug, unique: true
    add_index :companies, :embed_key, unique: true
  end
end
