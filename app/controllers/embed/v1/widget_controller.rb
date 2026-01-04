# frozen_string_literal: true

module Embed
  module V1
    class WidgetController < BaseController
      def init
        session = create_or_resume_session
        settings_data = build_widget_settings

        render json: {
          session_token: session.session_token,
          widget_settings: settings_data,
          welcome_message: get_welcome_message
        }
      rescue StandardError => e
        Rails.logger.error("Widget init error: #{e.message}")
        Rails.logger.error(e.backtrace.first(10).join("\n"))
        render json: { error: e.message }, status: :internal_server_error
      end

      def show_config
        render json: { widget_settings: build_widget_settings }
      end

      private

      def create_or_resume_session
        if params[:session_token].present?
          current_company.chat_sessions.find_by(session_token: params[:session_token]) ||
            create_new_session
        else
          create_new_session
        end
      end

      def create_new_session
        session = current_company.chat_sessions.create!(
          external_user_id: params[:external_user_id],
          user_context: params[:user_context] || {},
          locale: params[:locale] || "en"
        )

        UsageLog.record_session!(current_company)
        UsageLog.record_unique_user!(current_company) if params[:external_user_id].present?

        session
      end

      def build_widget_settings
        settings = current_company.settings || {}
        {
          company_name: current_company.name,
          primary_color: settings["primary_color"] || "#4F46E5",
          position: settings["position"] || "bottom-right",
          welcome_message: settings["welcome_message"],
          placeholder: settings["placeholder"] || "Ask me anything about AI-native development...",
          locale: settings["locale"] || "en"
        }
      end

      def get_welcome_message
        current_company.settings&.dig("welcome_message") ||
          "Hi! I'm here to help you become more AI-native in your development workflow. How can I assist you today?"
      end
    end
  end
end
