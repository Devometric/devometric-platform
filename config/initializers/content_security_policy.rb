# frozen_string_literal: true

# Be sure to restart your server when you modify this file.

# Define an application-wide content security policy.
# See the Securing Rails Applications Guide for more information:
# https://guides.rubyonrails.org/security.html#content-security-policy-header

Rails.application.configure do
  config.content_security_policy do |policy|
    policy.default_src :self
    policy.font_src    :self, :data, "https://fonts.gstatic.com"
    policy.img_src     :self, :data, :https
    policy.object_src  :none
    policy.script_src  :self, :unsafe_inline
    policy.style_src   :self, :unsafe_inline, "https://fonts.googleapis.com"
    policy.connect_src :self, "https://api.anthropic.com", "https://api.openai.com", "https://api.stripe.com"
    policy.frame_ancestors :self

    # Allow WebSocket connections for Action Cable / Turbo Streams
    policy.connect_src :self, "wss://#{ENV.fetch('HOST', 'localhost')}", "https://api.anthropic.com", "https://api.openai.com", "https://api.stripe.com"

    # Report CSP violations to this endpoint (optional - requires setting up a handler)
    # policy.report_uri "/csp-violation-report"
  end

  # Generate session nonces for permitted importmap, inline scripts, and inline styles.
  config.content_security_policy_nonce_generator = ->(request) { request.session.id.to_s }
  config.content_security_policy_nonce_directives = %w[script-src style-src]

  # Report violations without enforcing the policy in development/staging
  # Set to false in production to enforce the policy
  config.content_security_policy_report_only = Rails.env.development?
end
