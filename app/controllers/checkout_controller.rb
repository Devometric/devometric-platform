# frozen_string_literal: true

class CheckoutController < ApplicationController
  def success
    @session_id = params[:session_id]

    if @session_id.present?
      begin
        @session = Stripe::Checkout::Session.retrieve(@session_id)
        @customer = Stripe::Customer.retrieve(@session.customer) if @session.customer
      rescue Stripe::StripeError => e
        Rails.logger.error "Failed to retrieve checkout session: #{e.message}"
      end
    end
  end

  def cancel
    # User canceled the checkout
  end
end
