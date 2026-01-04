class AddCompanyToUsers < ActiveRecord::Migration[8.0]
  def change
    add_reference :users, :company, foreign_key: true
    add_column :users, :external_id, :string
    add_index :users, [:company_id, :external_id], unique: true, where: "external_id IS NOT NULL"
  end
end
