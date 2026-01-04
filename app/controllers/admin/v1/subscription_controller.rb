# frozen_string_literal: true

module Admin
  module V1
    class SubscriptionController < BaseController
      def show
        subscription = current_company.subscription

        if subscription
          render json: { subscription: subscription_json(subscription) }
        else
          render json: { subscription: nil }
        end
      end

      def checkout
        # Create Stripe Checkout session for subscription with 14-day trial
        subscription = current_company.subscription

        # Ensure we have a Stripe customer
        customer_id = ensure_stripe_customer

        # Create checkout session
        session = Stripe::Checkout::Session.create({
          customer: customer_id,
          mode: "subscription",
          line_items: [{
            price: Rails.application.config.stripe_prices[:b2b_monthly],
            quantity: 1
          }],
          subscription_data: {
            trial_period_days: 14,
            metadata: {
              company_id: current_company.id,
              company_name: current_company.name
            }
          },
          success_url: "#{app_url}/checkout/success?session_id={CHECKOUT_SESSION_ID}",
          cancel_url: "#{app_url}/checkout/cancel",
          metadata: {
            company_id: current_company.id
          }
        })

        render json: { checkout_url: session.url }
      rescue Stripe::StripeError => e
        render json: { error: e.message }, status: :service_unavailable
      end

      def portal
        # Create Stripe billing portal session
        subscription = current_company.subscription

        unless subscription&.stripe_customer_id
          render json: { error: "No billing account found" }, status: :not_found
          return
        end

        portal_session = create_stripe_portal_session(subscription.stripe_customer_id)

        render json: { url: portal_session.url }
      rescue Stripe::StripeError => e
        render json: { error: e.message }, status: :service_unavailable
      end

      private

      def app_url
        ENV.fetch("APP_URL", "http://localhost:3000")
      end

      def ensure_stripe_customer
        subscription = current_company.subscription

        if subscription&.stripe_customer_id.present?
          subscription.stripe_customer_id
        else
          # Create new Stripe customer
          customer = Stripe::Customer.create({
            email: current_company_admin.email,
            name: current_company.name,
            metadata: {
              company_id: current_company.id,
              company_slug: current_company.slug
            }
          })

          # Save customer ID to subscription
          if subscription
            subscription.update!(stripe_customer_id: customer.id)
          else
            current_company.create_subscription!(
              plan: "b2b",
              status: "trialing",
              stripe_customer_id: customer.id,
              current_period_start: Time.current,
              current_period_end: 14.days.from_now
            )
          end

          customer.id
        end
      end

      def subscription_json(subscription)
        {
          id: subscription.id,
          plan: subscription.plan,
          status: subscription.status,
          stripe_subscription_id: subscription.stripe_subscription_id,
          current_period_start: subscription.current_period_start&.iso8601,
          current_period_end: subscription.current_period_end&.iso8601,
          cancel_at_period_end: subscription.cancel_at_period_end,
          canceled_at: subscription.canceled_at&.iso8601,
          days_until_renewal: subscription.days_until_renewal,
          price: {
            amount: Subscription::PRICE_CENTS,
            currency: "eur",
            interval: "month"
          }
        }
      end

      def create_stripe_portal_session(customer_id)
        Stripe::BillingPortal::Session.create({
          customer: customer_id,
          return_url: "#{app_url}/admin/dashboard"
        })
      end
    end
  end
end
