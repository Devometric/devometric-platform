# frozen_string_literal: true

class CreateAuditLogs < ActiveRecord::Migration[8.0]
  def change
    create_table :audit_logs do |t|
      t.references :company, null: false, foreign_key: true
      t.references :actor, polymorphic: true, null: true
      t.string :action, null: false
      t.string :resource_type
      t.bigint :resource_id
      t.string :ip_address
      t.string :user_agent
      t.jsonb :metadata, default: {}
      t.datetime :created_at, null: false

      t.index [:company_id, :created_at]
      t.index [:action]
      t.index [:resource_type, :resource_id]
    end
  end
end
