# frozen_string_literal: true

class DeviseCreateUsers < ActiveRecord::Migration[8.0]
  def change
    create_table :users do |t|
      ## Database authenticatable
      t.string :email,              null: false, default: ""
      t.string :encrypted_password, null: false, default: ""

      ## Recoverable
      t.string   :reset_password_token
      t.datetime :reset_password_sent_at

      ## Rememberable
      t.datetime :remember_created_at

      ## Trackable
      t.integer  :sign_in_count, default: 0, null: false
      t.datetime :current_sign_in_at
      t.datetime :last_sign_in_at
      t.string   :current_sign_in_ip
      t.string   :last_sign_in_ip

      ## Profile
      t.string :name
      t.string :locale, default: "en"
      t.string :timezone, default: "UTC"

      ## Developer profile
      t.integer :experience_years
      t.string :primary_language  # javascript, python, java, go, ruby, etc.
      t.string :specialization    # frontend, backend, fullstack, mobile, devops, sre, platform, data, ml, security, qa, embedded, cloud, systems
      t.jsonb :tech_stack, default: []
      t.jsonb :preferences, default: {}
      t.boolean :onboarding_completed, default: false

      ## OAuth (GitHub)
      t.string :github_uid
      t.string :github_username

      t.timestamps null: false
    end

    add_index :users, :email,                unique: true
    add_index :users, :reset_password_token, unique: true
    add_index :users, :github_uid,           unique: true, where: "github_uid IS NOT NULL"
    add_index :users, :primary_language
    add_index :users, :specialization
  end
end
