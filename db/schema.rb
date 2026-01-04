# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 2025_12_26_170052) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "chat_sessions", force: :cascade do |t|
    t.bigint "company_id", null: false
    t.string "session_token", null: false
    t.string "external_user_id"
    t.jsonb "user_context", default: {}
    t.string "locale", default: "en"
    t.datetime "started_at"
    t.datetime "ended_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["company_id", "external_user_id"], name: "index_chat_sessions_on_company_id_and_external_user_id"
    t.index ["company_id"], name: "index_chat_sessions_on_company_id"
    t.index ["session_token"], name: "index_chat_sessions_on_session_token", unique: true
    t.index ["started_at"], name: "index_chat_sessions_on_started_at"
  end

  create_table "companies", force: :cascade do |t|
    t.string "name", null: false
    t.string "slug", null: false
    t.string "embed_key", null: false
    t.text "system_prompt"
    t.text "policies"
    t.text "coding_standards"
    t.text "work_culture"
    t.jsonb "tech_stack", default: []
    t.jsonb "settings", default: {}
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "anthropic_api_key"
    t.index ["embed_key"], name: "index_companies_on_embed_key", unique: true
    t.index ["slug"], name: "index_companies_on_slug", unique: true
  end

  create_table "company_admins", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string "current_sign_in_ip"
    t.string "last_sign_in_ip"
    t.bigint "company_id", null: false
    t.string "name"
    t.string "role", default: "admin", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["company_id"], name: "index_company_admins_on_company_id"
    t.index ["email"], name: "index_company_admins_on_email", unique: true
    t.index ["reset_password_token"], name: "index_company_admins_on_reset_password_token", unique: true
  end

  create_table "embed_domains", force: :cascade do |t|
    t.bigint "company_id", null: false
    t.string "domain", null: false
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["company_id", "domain"], name: "index_embed_domains_on_company_id_and_domain", unique: true
    t.index ["company_id"], name: "index_embed_domains_on_company_id"
  end

  create_table "messages", force: :cascade do |t|
    t.string "role"
    t.text "content"
    t.jsonb "code_blocks"
    t.integer "tokens_used"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "chat_session_id"
    t.index ["chat_session_id"], name: "index_messages_on_chat_session_id"
  end

  create_table "subscriptions", force: :cascade do |t|
    t.string "plan", default: "b2b", null: false
    t.string "status", default: "active", null: false
    t.string "stripe_customer_id"
    t.string "stripe_subscription_id"
    t.string "stripe_price_id"
    t.datetime "current_period_start"
    t.datetime "current_period_end"
    t.boolean "cancel_at_period_end", default: false
    t.datetime "canceled_at"
    t.jsonb "metadata", default: {}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "company_id"
    t.index ["company_id"], name: "index_subscriptions_on_company_id", unique: true, where: "(company_id IS NOT NULL)"
    t.index ["status"], name: "index_subscriptions_on_status"
    t.index ["stripe_subscription_id"], name: "index_subscriptions_on_stripe_subscription_id", unique: true, where: "(stripe_subscription_id IS NOT NULL)"
  end

  create_table "usage_logs", force: :cascade do |t|
    t.bigint "company_id", null: false
    t.date "date", null: false
    t.integer "sessions_count", default: 0, null: false
    t.integer "messages_count", default: 0, null: false
    t.integer "unique_users_count", default: 0, null: false
    t.integer "tokens_used", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["company_id", "date"], name: "index_usage_logs_on_company_id_and_date", unique: true
    t.index ["company_id"], name: "index_usage_logs_on_company_id"
    t.index ["date"], name: "index_usage_logs_on_date"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string "current_sign_in_ip"
    t.string "last_sign_in_ip"
    t.string "name"
    t.string "locale", default: "en"
    t.string "timezone", default: "UTC"
    t.integer "experience_years"
    t.string "primary_language"
    t.string "specialization"
    t.jsonb "tech_stack", default: []
    t.jsonb "preferences", default: {}
    t.boolean "onboarding_completed", default: false
    t.string "github_uid"
    t.string "github_username"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "company_id"
    t.string "external_id"
    t.index ["company_id", "external_id"], name: "index_users_on_company_id_and_external_id", unique: true, where: "(external_id IS NOT NULL)"
    t.index ["company_id"], name: "index_users_on_company_id"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["github_uid"], name: "index_users_on_github_uid", unique: true, where: "(github_uid IS NOT NULL)"
    t.index ["primary_language"], name: "index_users_on_primary_language"
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["specialization"], name: "index_users_on_specialization"
  end

  create_table "waitlist_entries", force: :cascade do |t|
    t.string "email", null: false
    t.string "company_name"
    t.string "company_size"
    t.text "use_case"
    t.string "source"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_waitlist_entries_on_email", unique: true
  end

  add_foreign_key "chat_sessions", "companies"
  add_foreign_key "company_admins", "companies"
  add_foreign_key "embed_domains", "companies"
  add_foreign_key "messages", "chat_sessions"
  add_foreign_key "subscriptions", "companies"
  add_foreign_key "usage_logs", "companies"
  add_foreign_key "users", "companies"
end
