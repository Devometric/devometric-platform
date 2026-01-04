# frozen_string_literal: true

module Admin
  module V1
    class ConfigurationController < BaseController
      def show
        render json: { configuration: configuration_json }
      end

      def update
        current_company.update!(configuration_params)
        render json: { configuration: configuration_json }
      end

      def test
        # Test the AI configuration with a sample prompt
        test_session = current_company.chat_sessions.create!(
          session_token: SecureRandom.urlsafe_base64(24),
          external_user_id: "test-admin-#{current_admin.id}"
        )

        chat_service = ::AI::CompanyChatService.new(test_session)
        result = chat_service.send_message("Hello! Can you briefly introduce yourself and what you can help with?")

        # Clean up test session
        test_session.destroy

        render json: {
          success: true,
          response: result[:message].content,
          usage: result[:usage]
        }
      rescue ::AI::CompanyChatService::ChatError => e
        render json: { success: false, error: e.message }, status: :service_unavailable
      end

      private

      def configuration_params
        params.require(:configuration).permit(
          :system_prompt,
          :policies,
          :coding_standards,
          :work_culture,
          tech_stack: [],
          settings: {}
        )
      end

      def configuration_json
        {
          system_prompt: current_company.system_prompt,
          policies: current_company.policies,
          coding_standards: current_company.coding_standards,
          work_culture: current_company.work_culture,
          tech_stack: current_company.tech_stack,
          settings: current_company.settings,
          embed_key: current_company.embed_key
        }
      end
    end
  end
end
