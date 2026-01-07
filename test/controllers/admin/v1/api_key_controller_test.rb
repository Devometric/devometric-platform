# frozen_string_literal: true

require "test_helper"

class Admin::V1::ApiKeyControllerTest < ActionDispatch::IntegrationTest
  setup do
    @admin = company_admins(:admin_john)
    @company = @admin.company
  end

  test "updating API key creates audit log" do
    assert_difference "AuditLog.count", 1 do
      patch "/admin/v1/api_key",
            params: { api_key: "sk-ant-test-key-12345678" }.to_json,
            headers: auth_headers(@admin)
    end

    assert_response :success

    audit = AuditLog.last
    assert_equal "api_key_update", audit.action
    assert_equal @company.id, audit.company_id
    assert_equal @admin.id, audit.actor_id
    # Should store a preview, not the full key
    assert audit.metadata["key_preview"].present?
    assert audit.metadata["key_preview"].include?("...")
  end

  test "deleting API key creates audit log" do
    # First set a key
    @company.update!(anthropic_api_key: "sk-ant-test-key-to-delete")

    assert_difference "AuditLog.count", 1 do
      delete "/admin/v1/api_key",
             headers: auth_headers(@admin)
    end

    assert_response :success

    audit = AuditLog.last
    assert_equal "api_key_delete", audit.action
    assert_equal @company.id, audit.company_id
  end

  test "rejects invalid API key format" do
    assert_no_difference "AuditLog.count" do
      patch "/admin/v1/api_key",
            params: { api_key: "invalid-key-format" }.to_json,
            headers: auth_headers(@admin)
    end

    assert_response :unprocessable_entity
  end

  test "API key endpoint requires authentication" do
    patch "/admin/v1/api_key",
          params: { api_key: "sk-ant-test-key" }.to_json,
          headers: json_headers

    assert_response :unauthorized
  end
end
