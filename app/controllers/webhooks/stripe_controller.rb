# frozen_string_literal: true

module Webhooks
  class StripeController < ApplicationController
    skip_before_action :verify_authenticity_token

    def create
      payload = request.body.read
      sig_header = request.env["HTTP_STRIPE_SIGNATURE"]
      webhook_secret = Rails.application.config.stripe_webhook_secret

      begin
        event = Stripe::Webhook.construct_event(payload, sig_header, webhook_secret)
      rescue JSON::ParserError
        render json: { error: "Invalid payload" }, status: :bad_request
        return
      rescue Stripe::SignatureVerificationError
        render json: { error: "Invalid signature" }, status: :bad_request
        return
      end

      # Handle the event
      case event.type
      when "checkout.session.completed"
        handle_checkout_session_completed(event.data.object)
      when "customer.subscription.created"
        handle_subscription_created(event.data.object)
      when "customer.subscription.updated"
        handle_subscription_updated(event.data.object)
      when "customer.subscription.deleted"
        handle_subscription_deleted(event.data.object)
      when "invoice.payment_succeeded"
        handle_payment_succeeded(event.data.object)
      when "invoice.payment_failed"
        handle_payment_failed(event.data.object)
      when "customer.subscription.trial_will_end"
        handle_trial_will_end(event.data.object)
      else
        Rails.logger.info "Unhandled Stripe event type: #{event.type}"
      end

      render json: { received: true }
    end

    private

    def handle_checkout_session_completed(session)
      Rails.logger.info "Processing checkout.session.completed: #{session.id}"

      return unless session.mode == "subscription"

      # Metadata is a hash-like object
      company_id = session.metadata&.[]("company_id")

      if company_id.present?
        # Existing company - update their subscription
        company = Company.find_by(id: company_id)
        return unless company
      else
        # New signup from homepage - create company and admin
        company = create_company_from_checkout(session)
        return unless company
      end

      # Fetch the full subscription from Stripe
      stripe_subscription = Stripe::Subscription.retrieve(session.subscription)
      first_item = stripe_subscription.items.data.first

      subscription = company.subscription || company.build_subscription
      subscription.update!(
        stripe_customer_id: session.customer,
        stripe_subscription_id: stripe_subscription.id,
        stripe_price_id: first_item&.price&.id,
        status: map_stripe_status(stripe_subscription.status),
        # Stripe API 2025-12-15.clover: period dates are now on subscription items
        current_period_start: Time.at(first_item&.current_period_start || stripe_subscription.start_date),
        current_period_end: Time.at(first_item&.current_period_end || stripe_subscription.trial_end || stripe_subscription.billing_cycle_anchor),
        plan: "b2b"
      )

      Rails.logger.info "Subscription created for company #{company.name} (#{company.id})"
    end

    def create_company_from_checkout(session)
      # Get customer details from Stripe
      customer = Stripe::Customer.retrieve(session.customer)
      email = customer.email

      # Get company name from custom fields
      company_name = extract_company_name(session) || email.split("@").first.titleize

      # Generate unique slug
      base_slug = company_name.parameterize
      slug = base_slug
      counter = 1
      while Company.exists?(slug: slug)
        slug = "#{base_slug}-#{counter}"
        counter += 1
      end

      # Create company
      company = Company.create!(
        name: company_name,
        slug: slug,
        embed_key: SecureRandom.hex(16),
        active: true
      )

      # Create admin user with random password (they'll reset via email)
      temp_password = SecureRandom.hex(16)
      company.company_admins.create!(
        email: email,
        password: temp_password,
        password_confirmation: temp_password,
        name: company_name,
        role: "owner"
      )

      Rails.logger.info "Created new company #{company.name} (#{company.id}) from checkout"

      company
    rescue ActiveRecord::RecordInvalid => e
      Rails.logger.error "Failed to create company from checkout: #{e.message}"
      nil
    end

    def extract_company_name(session)
      custom_fields = session.try(:custom_fields) || session.try(:[], "custom_fields")
      return nil unless custom_fields.present?

      company_field = custom_fields.find do |f|
        field_key = f.try(:key) || f.try(:[], "key") || f.try(:[], :key)
        field_key == "company_name"
      end
      return nil unless company_field

      # Try different access patterns for the text value
      text = company_field.try(:text) || company_field.try(:[], "text") || company_field.try(:[], :text)
      text.try(:value) || text.try(:[], "value") || text.try(:[], :value)
    rescue StandardError => e
      Rails.logger.warn "Failed to extract company name: #{e.message}"
      nil
    end

    def handle_subscription_created(stripe_subscription)
      update_subscription_from_stripe(stripe_subscription)
    end

    def handle_subscription_updated(stripe_subscription)
      update_subscription_from_stripe(stripe_subscription)
    end

    def handle_subscription_deleted(stripe_subscription)
      subscription = Subscription.find_by(stripe_subscription_id: stripe_subscription.id)
      return unless subscription

      subscription.update!(
        status: "canceled",
        canceled_at: Time.current
      )

      Rails.logger.info "Subscription canceled for company #{subscription.company&.name}"
    end

    def handle_payment_succeeded(invoice)
      # Stripe API 2025-12-15.clover moved subscription to parent.subscription_details
      subscription_id = invoice.try(:subscription) || invoice.parent&.subscription_details&.subscription
      return unless subscription_id

      subscription = Subscription.find_by(stripe_subscription_id: subscription_id)
      return unless subscription

      # Update status to active if it was past_due
      if subscription.past_due?
        subscription.update!(status: "active")
      end

      Rails.logger.info "Payment succeeded for subscription #{subscription.id}"
    end

    def handle_payment_failed(invoice)
      # Stripe API 2025-12-15.clover moved subscription to parent.subscription_details
      subscription_id = invoice.try(:subscription) || invoice.parent&.subscription_details&.subscription
      return unless subscription_id

      subscription = Subscription.find_by(stripe_subscription_id: subscription_id)
      return unless subscription

      subscription.update!(status: "past_due")

      Rails.logger.info "Payment failed for subscription #{subscription.id}"
    end

    def handle_trial_will_end(stripe_subscription)
      subscription = Subscription.find_by(stripe_subscription_id: stripe_subscription.id)
      return unless subscription

      # Could send an email notification here
      Rails.logger.info "Trial ending soon for subscription #{subscription.id}"
    end

    def update_subscription_from_stripe(stripe_subscription)
      # Find subscription by stripe_subscription_id or customer_id
      subscription = Subscription.find_by(stripe_subscription_id: stripe_subscription.id)
      subscription ||= Subscription.find_by(stripe_customer_id: stripe_subscription.customer)

      return unless subscription

      first_item = stripe_subscription.items.data.first
      subscription.update!(
        stripe_subscription_id: stripe_subscription.id,
        stripe_price_id: first_item&.price&.id,
        status: map_stripe_status(stripe_subscription.status),
        # Stripe API 2025-12-15.clover: period dates are now on subscription items
        current_period_start: Time.at(first_item&.current_period_start || stripe_subscription.start_date),
        current_period_end: Time.at(first_item&.current_period_end || stripe_subscription.trial_end || stripe_subscription.billing_cycle_anchor),
        cancel_at_period_end: stripe_subscription.cancel_at_period_end,
        canceled_at: stripe_subscription.canceled_at ? Time.at(stripe_subscription.canceled_at) : nil
      )

      Rails.logger.info "Subscription updated: #{subscription.id} -> #{subscription.status}"
    end

    def map_stripe_status(stripe_status)
      case stripe_status
      when "active" then "active"
      when "trialing" then "trialing"
      when "past_due" then "past_due"
      when "unpaid" then "unpaid"
      when "canceled", "incomplete_expired" then "canceled"
      else "active"
      end
    end
  end
end
