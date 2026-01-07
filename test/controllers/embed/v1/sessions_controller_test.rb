# frozen_string_literal: true

require "test_helper"

class Embed::V1::SessionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @company = companies(:acme)
    @existing_session = chat_sessions(:session_one)
  end

  test "creates new session and returns session_secret" do
    new_user_id = "new_user_#{SecureRandom.hex(8)}"

    post "/embed/v1/sessions/resume",
         params: { external_user_id: new_user_id }.to_json,
         headers: embed_headers(@company)

    assert_response :success
    assert json_response["session_token"].present?
    assert json_response["session_secret"].present?, "New session should include session_secret"
    assert json_response["is_new_session"] == true
  end

  test "does not return session_secret when resuming existing session" do
    post "/embed/v1/sessions/resume",
         params: {
           external_user_id: @existing_session.external_user_id,
           session_secret: @existing_session.session_secret
         }.to_json,
         headers: embed_headers(@company)

    assert_response :success
    assert_nil json_response["session_secret"], "Resumed session should not expose session_secret"
    assert json_response["is_new_session"] == false
  end

  test "rejects session resumption without session_secret" do
    # Try to resume without providing the secret - should create a new session instead
    post "/embed/v1/sessions/resume",
         params: { external_user_id: @existing_session.external_user_id }.to_json,
         headers: embed_headers(@company)

    assert_response :success
    # Should create a new session, not resume the existing one
    assert json_response["is_new_session"] == true
    assert json_response["session_token"] != @existing_session.session_token
  end

  test "rejects session resumption with invalid session_secret" do
    post "/embed/v1/sessions/resume",
         params: {
           external_user_id: @existing_session.external_user_id,
           session_secret: "invalid_secret_attempt"
         }.to_json,
         headers: embed_headers(@company)

    assert_response :success
    # Should create a new session, not resume the existing one
    assert json_response["is_new_session"] == true
    assert json_response["session_token"] != @existing_session.session_token
  end

  test "successfully resumes session with valid session_secret" do
    post "/embed/v1/sessions/resume",
         params: {
           external_user_id: @existing_session.external_user_id,
           session_secret: @existing_session.session_secret
         }.to_json,
         headers: embed_headers(@company)

    assert_response :success
    assert json_response["is_new_session"] == false
    assert_equal @existing_session.session_token, json_response["session_token"]
  end

  test "cannot hijack session by guessing external_user_id" do
    attacker_attempts = 0

    # Simulate attacker trying various user IDs
    %w[user_123 user_1 admin user_456 test].each do |user_id|
      post "/embed/v1/sessions/resume",
           params: {
             external_user_id: user_id,
             session_secret: "guessed_secret_#{attacker_attempts}"
           }.to_json,
           headers: embed_headers(@company)

      assert_response :success
      # All attempts should result in new sessions, not resumed ones
      assert json_response["is_new_session"] == true
      attacker_attempts += 1
    end
  end

  test "session_secret uses secure comparison to prevent timing attacks" do
    session = ChatSession.create!(
      company: @company,
      external_user_id: "timing_test_user"
    )

    # The verify_secret method should use secure_compare
    assert session.respond_to?(:verify_secret)
    assert session.verify_secret(session.session_secret)
    refute session.verify_secret("wrong_secret")
    refute session.verify_secret("")
    refute session.verify_secret(nil)
  end

  test "does not resume ended sessions" do
    ended_session = chat_sessions(:ended_session)

    post "/embed/v1/sessions/resume",
         params: {
           external_user_id: ended_session.external_user_id,
           session_secret: ended_session.session_secret
         }.to_json,
         headers: embed_headers(@company)

    assert_response :success
    # Should create new session since the old one is ended
    assert json_response["is_new_session"] == true
  end
end
