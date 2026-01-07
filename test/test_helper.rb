# frozen_string_literal: true

ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # Add more helper methods to be used by all tests here...
  end
end

module ActionDispatch
  class IntegrationTest
    # Helper to set JSON headers
    def json_headers(extra = {})
      { "Content-Type" => "application/json", "Accept" => "application/json" }.merge(extra)
    end

    # Helper to parse JSON response
    def json_response
      JSON.parse(response.body)
    end

    # Helper to generate JWT token for admin
    def jwt_token_for(admin)
      JWT.encode(
        { admin_id: admin.id, exp: 24.hours.from_now.to_i },
        Rails.application.credentials.secret_key_base || ENV.fetch("SECRET_KEY_BASE"),
        "HS256"
      )
    end

    # Helper to set authorization header
    def auth_headers(admin)
      json_headers("Authorization" => "Bearer #{jwt_token_for(admin)}")
    end

    # Helper to set embed headers
    def embed_headers(company, origin: "https://allowed-domain.com")
      headers = json_headers("X-Embed-Key" => company.embed_key)
      headers["Origin"] = origin if origin
      headers
    end
  end
end
