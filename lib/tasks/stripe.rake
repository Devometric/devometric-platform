# frozen_string_literal: true

module StripeTaskHelpers
  module_function

  def find_or_create_product
    # Try to find existing product
    products = Stripe::Product.list(limit: 100)
    existing = products.data.find { |p| p.name == "Devometric Team Plan" && p.active }

    if existing
      puts "Found existing product"
      existing
    else
      puts "Creating new product..."
      Stripe::Product.create({
        name: "Devometric Team Plan",
        description: "AI Skills Platform for Engineering Teams - Cloud hosted with unlimited users"
      })
    end
  end

  def find_or_create_price(product)
    # Try to find existing price
    prices = Stripe::Price.list(product: product.id, active: true, limit: 100)
    existing = prices.data.find do |p|
      p.unit_amount == 18900 &&
        p.currency == "eur" &&
        p.recurring&.interval == "month"
    end

    if existing
      puts "Found existing price"
      existing
    else
      puts "Creating new price..."
      Stripe::Price.create({
        product: product.id,
        unit_amount: 18900, # 189 EUR
        currency: "eur",
        recurring: {
          interval: "month"
        }
      })
    end
  end
end

namespace :stripe do
  desc "Set up Stripe product and price for Devometric subscription"
  task setup: :environment do
    puts "Setting up Stripe products and prices..."

    # Check if Stripe API key is configured
    unless Stripe.api_key.present?
      puts "Error: STRIPE_SECRET_KEY is not set in environment variables"
      exit 1
    end

    # Create or find the product
    product = StripeTaskHelpers.find_or_create_product
    puts "Product: #{product.name} (#{product.id})"

    # Create or find the price
    price = StripeTaskHelpers.find_or_create_price(product)
    puts "Price: #{price.unit_amount / 100} #{price.currency.upcase}/#{price.recurring.interval} (#{price.id})"

    puts "\n" + "=" * 60
    puts "Add these to your .env file:"
    puts "=" * 60
    puts "STRIPE_PRICE_B2B_MONTHLY=#{price.id}"
    puts "=" * 60
  end

  desc "Configure Stripe webhook endpoint"
  task webhook_setup: :environment do
    puts "Creating Stripe webhook endpoint..."

    app_url = ENV.fetch("APP_URL", nil)
    unless app_url
      puts "Error: APP_URL is not set in environment variables"
      exit 1
    end

    webhook = Stripe::WebhookEndpoint.create({
      url: "#{app_url}/webhooks/stripe",
      enabled_events: [
        "checkout.session.completed",
        "customer.subscription.created",
        "customer.subscription.updated",
        "customer.subscription.deleted",
        "invoice.payment_succeeded",
        "invoice.payment_failed",
        "customer.subscription.trial_will_end"
      ]
    })

    puts "\n" + "=" * 60
    puts "Webhook created!"
    puts "=" * 60
    puts "Webhook ID: #{webhook.id}"
    puts "Webhook URL: #{webhook.url}"
    puts "\nAdd this to your .env file:"
    puts "STRIPE_WEBHOOK_SECRET=#{webhook.secret}"
    puts "=" * 60
  end

  desc "Configure Stripe Customer Portal"
  task portal_setup: :environment do
    puts "Configuring Stripe Customer Portal..."

    # Get the price ID
    price_id = ENV.fetch("STRIPE_PRICE_B2B_MONTHLY", nil)
    unless price_id
      puts "Error: STRIPE_PRICE_B2B_MONTHLY is not set. Run `rails stripe:setup` first."
      exit 1
    end

    configuration = Stripe::BillingPortal::Configuration.create({
      business_profile: {
        headline: "Manage your Devometric subscription"
      },
      features: {
        customer_update: {
          enabled: true,
          allowed_updates: %w[email address]
        },
        invoice_history: {
          enabled: true
        },
        payment_method_update: {
          enabled: true
        },
        subscription_cancel: {
          enabled: true,
          mode: "at_period_end",
          cancellation_reason: {
            enabled: true,
            options: %w[too_expensive missing_features switched_service unused too_complex other]
          }
        },
        subscription_update: {
          enabled: false
        }
      },
      default_return_url: "#{ENV.fetch('APP_URL', 'http://localhost:3000')}/admin/dashboard"
    })

    puts "\n" + "=" * 60
    puts "Customer Portal configured!"
    puts "Configuration ID: #{configuration.id}"
    puts "=" * 60
  end
end
