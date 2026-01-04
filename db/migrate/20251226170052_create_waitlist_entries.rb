class CreateWaitlistEntries < ActiveRecord::Migration[8.0]
  def change
    create_table :waitlist_entries do |t|
      t.string :email, null: false
      t.string :company_name
      t.string :company_size
      t.text :use_case
      t.string :source

      t.timestamps
    end
    add_index :waitlist_entries, :email, unique: true
  end
end
