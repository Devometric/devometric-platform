class ModifySubscriptionsForCompany < ActiveRecord::Migration[8.0]
  def change
    # Add company reference (with index: false to avoid duplicate, we add unique index below)
    add_reference :subscriptions, :company, foreign_key: true, index: false

    # Remove user reference (B2B model - subscriptions belong to companies, not users)
    remove_foreign_key :subscriptions, :users
    remove_index :subscriptions, :user_id
    remove_column :subscriptions, :user_id, :bigint

    # Update plan to only support b2b plan
    change_column_default :subscriptions, :plan, from: nil, to: 'b2b'

    # Add unique index on company_id (one subscription per company)
    add_index :subscriptions, :company_id, unique: true, where: "company_id IS NOT NULL"
  end
end
