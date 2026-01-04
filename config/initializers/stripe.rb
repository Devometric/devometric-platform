# frozen_string_literal: true

Stripe.api_key = ENV.fetch("STRIPE_SECRET_KEY", nil)

# Stripe API version - use a specific version for stability
Stripe.api_version = "2025-12-15.clover"

# Configure Stripe webhook signing secret
Rails.application.config.stripe_webhook_secret = ENV.fetch("STRIPE_WEBHOOK_SECRET", nil)

# Stripe Price IDs for different plans
Rails.application.config.stripe_prices = {
  b2b_monthly: ENV.fetch("STRIPE_PRICE_B2B_MONTHLY", nil)
}
