# frozen_string_literal: true

class PublicCheckoutController < ApplicationController
  def create
    # Create a Stripe Checkout session for new signups
    # The customer/company will be created when the checkout completes

    session = Stripe::Checkout::Session.create({
      mode: "subscription",
      line_items: [{
        price: Rails.application.config.stripe_prices[:b2b_monthly],
        quantity: 1
      }],
      subscription_data: {
        trial_period_days: 14,
        metadata: {
          source: "homepage"
        }
      },
      success_url: "#{app_url}/checkout/success?session_id={CHECKOUT_SESSION_ID}",
      cancel_url: "#{app_url}/checkout/cancel",
      # Collect customer email and billing details
      billing_address_collection: "required",
      # Note: customer_creation is not needed in subscription mode - Stripe creates customer automatically
      # Custom fields for company name
      custom_fields: [
        {
          key: "company_name",
          label: { type: "custom", custom: "Company Name" },
          type: "text"
        }
      ]
    })

    redirect_to session.url, allow_other_host: true
  rescue Stripe::StripeError => e
    Rails.logger.error "Stripe checkout error: #{e.message}"
    redirect_to root_path, alert: "Unable to start checkout. Please try again."
  end

  private

  def app_url
    ENV.fetch("APP_URL", "http://localhost:3000")
  end
end
