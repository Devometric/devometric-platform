# frozen_string_literal: true

module Admin
  module V1
    class ApiKeyController < BaseController
      def show
        render json: {
          has_custom_key: current_company.uses_own_api_key?,
          key_preview: key_preview,
          using_platform_key: !current_company.uses_own_api_key?
        }
      end

      def update
        api_key = params.require(:api_key)

        # Validate the API key format
        unless valid_api_key_format?(api_key)
          return render json: { error: "Invalid API key format" }, status: :unprocessable_entity
        end

        current_company.update!(anthropic_api_key: api_key)

        AuditLog.log!(
          company: current_company,
          action: "api_key_update",
          actor: current_company_admin,
          request: request,
          metadata: { key_preview: key_preview }
        )

        render json: {
          success: true,
          has_custom_key: true,
          key_preview: key_preview
        }
      end

      def destroy
        current_company.update!(anthropic_api_key: nil)

        AuditLog.log!(
          company: current_company,
          action: "api_key_delete",
          actor: current_company_admin,
          request: request
        )

        render json: {
          success: true,
          has_custom_key: false,
          using_platform_key: true
        }
      end

      def test
        api_key = params[:api_key] || current_company.effective_api_key

        unless api_key.present?
          return render json: { success: false, error: "No API key configured" }, status: :unprocessable_entity
        end

        client = ::AI::ClaudeClient.new(api_key: api_key)
        result = client.chat(
          messages: [{ role: "user", content: "Say 'API key is working!' and nothing else." }],
          max_tokens: 50
        )

        render json: {
          success: true,
          message: "API key is valid",
          response: result[:content]
        }
      rescue ::AI::ClaudeClient::AuthenticationError
        render json: { success: false, error: "Invalid API key" }, status: :unauthorized
      rescue ::AI::ClaudeClient::ApiError => e
        render json: { success: false, error: e.message }, status: :service_unavailable
      end

      private

      def key_preview
        return nil unless current_company.anthropic_api_key.present?

        key = current_company.anthropic_api_key
        "#{key[0..7]}...#{key[-4..]}"
      end

      def valid_api_key_format?(key)
        key.present? && key.start_with?("sk-ant-")
      end
    end
  end
end
