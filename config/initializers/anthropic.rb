# frozen_string_literal: true

# Anthropic API configuration
# In production, use Rails credentials or environment variables
# For development, you can set ANTHROPIC_API_KEY environment variable

Rails.application.config.anthropic_api_key = ENV.fetch("ANTHROPIC_API_KEY") do
  Rails.application.credentials.dig(:anthropic, :api_key)
end
