# frozen_string_literal: true

require "test_helper"

class EmbedAuthenticatableTest < ActionDispatch::IntegrationTest
  setup do
    @company = companies(:acme)
  end

  test "rejects requests without Origin header" do
    # This tests the domain whitelisting bypass fix
    post "/embed/v1/sessions/resume",
         params: { external_user_id: "test_user" }.to_json,
         headers: json_headers("X-Embed-Key" => @company.embed_key)

    assert_response :unauthorized
    assert_equal "Unauthorized", json_response["error"]
  end

  test "rejects requests without Referer header when Origin is missing" do
    post "/embed/v1/sessions/resume",
         params: { external_user_id: "test_user" }.to_json,
         headers: json_headers("X-Embed-Key" => @company.embed_key)
         # No Origin or Referer header

    assert_response :unauthorized
  end

  test "accepts requests with valid Origin header from whitelisted domain" do
    post "/embed/v1/sessions/resume",
         params: { external_user_id: "new_user_#{SecureRandom.hex}" }.to_json,
         headers: embed_headers(@company, origin: "https://allowed-domain.com")

    assert_response :success
  end

  test "rejects requests from non-whitelisted domain" do
    post "/embed/v1/sessions/resume",
         params: { external_user_id: "test_user" }.to_json,
         headers: embed_headers(@company, origin: "https://evil-domain.com")

    assert_response :unauthorized
  end

  test "rejects requests with invalid embed key" do
    post "/embed/v1/sessions/resume",
         params: { external_user_id: "test_user" }.to_json,
         headers: embed_headers(@company, origin: "https://allowed-domain.com")
                   .merge("X-Embed-Key" => "invalid_key")

    assert_response :unauthorized
  end

  test "rejects requests from inactive company" do
    inactive = companies(:inactive_company)

    post "/embed/v1/sessions/resume",
         params: { external_user_id: "test_user" }.to_json,
         headers: embed_headers(inactive, origin: "https://allowed-domain.com")
                   .merge("X-Embed-Key" => inactive.embed_key)

    assert_response :unauthorized
  end

  test "rejects requests with inactive embed domain" do
    post "/embed/v1/sessions/resume",
         params: { external_user_id: "test_user" }.to_json,
         headers: embed_headers(@company, origin: "https://inactive-domain.com")

    assert_response :unauthorized
  end

  test "allows localhost in development" do
    # This test only works in development environment
    skip unless Rails.env.development?

    post "/embed/v1/sessions/resume",
         params: { external_user_id: "test_user" }.to_json,
         headers: embed_headers(@company, origin: "http://localhost:3000")

    assert_response :success
  end
end
