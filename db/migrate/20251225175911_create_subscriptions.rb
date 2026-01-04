class CreateSubscriptions < ActiveRecord::Migration[8.0]
  def change
    create_table :subscriptions do |t|
      t.references :user, null: false, foreign_key: true
      t.string :plan, null: false  # starter, pro, team (no free tier)
      t.string :status, null: false, default: "active"
      t.string :stripe_customer_id
      t.string :stripe_subscription_id
      t.string :stripe_price_id
      t.datetime :current_period_start
      t.datetime :current_period_end
      t.boolean :cancel_at_period_end, default: false
      t.datetime :canceled_at
      t.jsonb :metadata, default: {}

      t.timestamps
    end
    add_index :subscriptions, :stripe_subscription_id, unique: true, where: "stripe_subscription_id IS NOT NULL"
    add_index :subscriptions, :status
  end
end
