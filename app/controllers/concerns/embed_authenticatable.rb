# frozen_string_literal: true

module EmbedAuthenticatable
  extend ActiveSupport::Concern

  included do
    before_action :authenticate_embed_request!
    before_action :verify_subscription!
  end

  private

  def authenticate_embed_request!
    @current_company = find_company_by_embed_key
    return if @current_company && domain_allowed?

    render json: { error: "Unauthorized" }, status: :unauthorized
  end

  def verify_subscription!
    return if @current_company&.has_active_subscription?

    render json: { error: "Subscription required" }, status: :payment_required
  end

  def find_company_by_embed_key
    embed_key = request.headers["X-Embed-Key"] || params[:embed_key]
    return nil if embed_key.blank?

    Company.active.find_by(embed_key: embed_key)
  end

  def domain_allowed?
    origin = request.headers["Origin"] || request.headers["Referer"]
    return true if origin.blank? # Allow server-to-server requests

    domain = extract_domain(origin)
    return true if Rails.env.development? && domain.in?(%w[localhost 127.0.0.1])

    @current_company.domain_allowed?(domain)
  end

  def extract_domain(url)
    uri = URI.parse(url)
    uri.host
  rescue URI::InvalidURIError
    nil
  end

  def current_company
    @current_company
  end
end
