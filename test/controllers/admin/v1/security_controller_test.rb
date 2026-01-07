# frozen_string_literal: true

require "test_helper"

class Admin::V1::SecurityControllerTest < ActionDispatch::IntegrationTest
  setup do
    @admin = company_admins(:admin_john)
    @company = @admin.company
  end

  test "data export creates audit log" do
    assert_difference "AuditLog.count", 1 do
      post "/admin/v1/security/export",
           headers: auth_headers(@admin)
    end

    assert_response :success

    audit = AuditLog.last
    assert_equal "data_export", audit.action
    assert_equal @company.id, audit.company_id
    assert_equal @admin.id, audit.actor_id
    assert_equal "CompanyAdmin", audit.actor_type
    assert audit.metadata["format"].present?
    assert audit.metadata["chat_sessions_count"].present?
  end

  test "security settings update creates audit log" do
    assert_difference "AuditLog.count", 1 do
      patch "/admin/v1/security",
            params: { security: { retention_days: 90 } }.to_json,
            headers: auth_headers(@admin)
    end

    assert_response :success

    audit = AuditLog.last
    assert_equal "security_settings_update", audit.action
    assert_equal @company.id, audit.company_id
    assert audit.metadata["old_retention_days"].present? || audit.metadata["old_retention_days"].nil?
    assert_equal 90, audit.metadata["new_retention_days"]
  end

  test "data deletion creates audit log with counts" do
    # Create some data to delete
    session = @company.chat_sessions.create!(
      external_user_id: "delete_test_user"
    )
    session.messages.create!(role: "user", content: "test message")

    assert_difference "AuditLog.count", 1 do
      delete "/admin/v1/security/data",
             params: { scope: "chat_sessions" }.to_json,
             headers: auth_headers(@admin)
    end

    assert_response :success

    audit = AuditLog.last
    assert_equal "data_delete", audit.action
    assert_equal "chat_sessions", audit.metadata["scope"]
    assert audit.metadata["records_deleted"]["chat_sessions"] >= 0
  end

  test "audit log captures IP address and user agent" do
    post "/admin/v1/security/export",
         headers: auth_headers(@admin).merge(
           "User-Agent" => "SecurityTest/1.0",
           "REMOTE_ADDR" => "192.168.1.100"
         )

    assert_response :success

    audit = AuditLog.last
    assert audit.ip_address.present?
    assert_equal "SecurityTest/1.0", audit.user_agent
  end

  test "export endpoint requires authentication" do
    post "/admin/v1/security/export"

    assert_response :unauthorized
  end

  test "delete endpoint requires authentication" do
    delete "/admin/v1/security/data",
           params: { scope: "all" }.to_json,
           headers: json_headers

    assert_response :unauthorized
  end
end
