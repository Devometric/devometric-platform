class CreateEmbedDomains < ActiveRecord::Migration[8.0]
  def change
    create_table :embed_domains do |t|
      t.references :company, null: false, foreign_key: true
      t.string :domain, null: false
      t.boolean :active, default: true, null: false

      t.timestamps
    end
    add_index :embed_domains, [:company_id, :domain], unique: true
  end
end
