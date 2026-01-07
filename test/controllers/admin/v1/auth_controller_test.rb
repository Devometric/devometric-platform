# frozen_string_literal: true

require "test_helper"

class Admin::V1::AuthControllerTest < ActionDispatch::IntegrationTest
  setup do
    @admin = company_admins(:admin_john)
  end

  test "successful login creates audit log" do
    assert_difference "AuditLog.count", 1 do
      post "/admin/v1/auth/login",
           params: { auth: { email: @admin.email, password: "password123" } }.to_json,
           headers: json_headers
    end

    assert_response :success

    audit = AuditLog.last
    assert_equal "admin_login", audit.action
    assert_equal @admin.company_id, audit.company_id
    assert_equal @admin.id, audit.actor_id
  end

  test "failed login with valid email creates audit log" do
    assert_difference "AuditLog.count", 1 do
      post "/admin/v1/auth/login",
           params: { auth: { email: @admin.email, password: "wrong_password" } }.to_json,
           headers: json_headers
    end

    assert_response :unauthorized

    audit = AuditLog.last
    assert_equal "admin_login_failed", audit.action
    assert_equal @admin.company_id, audit.company_id
    assert_equal "invalid_password", audit.metadata["reason"]
  end

  test "failed login with invalid email does not create audit log" do
    assert_no_difference "AuditLog.count" do
      post "/admin/v1/auth/login",
           params: { auth: { email: "nonexistent@example.com", password: "password" } }.to_json,
           headers: json_headers
    end

    assert_response :unauthorized
  end

  test "login returns JWT token" do
    post "/admin/v1/auth/login",
         params: { auth: { email: @admin.email, password: "password123" } }.to_json,
         headers: json_headers

    assert_response :success
    assert json_response["token"].present?
    assert json_response["admin"]["email"] == @admin.email
  end

  test "login is case insensitive for email" do
    post "/admin/v1/auth/login",
         params: { auth: { email: @admin.email.upcase, password: "password123" } }.to_json,
         headers: json_headers

    assert_response :success
    assert json_response["token"].present?
  end
end
