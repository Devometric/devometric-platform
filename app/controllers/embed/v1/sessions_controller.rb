# frozen_string_literal: true

module Embed
  module V1
    class SessionsController < BaseController
      before_action :set_chat_session, only: [:history, :update_context]

      def resume
        session = find_existing_session || create_new_session

        render json: {
          session_token: session.session_token,
          messages: session.messages.ordered.map { |m| message_json(m) }
        }
      end

      def history
        messages = @chat_session.messages.ordered

        render json: {
          messages: messages.map { |m| message_json(m) },
          session: {
            started_at: @chat_session.started_at,
            message_count: messages.count
          }
        }
      end

      def update_context
        @chat_session.update!(user_context: context_params.to_h)
        render json: { success: true }
      end

      private

      def set_chat_session
        @chat_session = current_company.chat_sessions.find_by!(session_token: params[:session_token])
      end

      def find_existing_session
        return nil if params[:external_user_id].blank?

        current_company.chat_sessions
          .where(external_user_id: params[:external_user_id])
          .where(ended_at: nil)
          .order(created_at: :desc)
          .first
      end

      def create_new_session
        session = current_company.chat_sessions.create!(
          external_user_id: params[:external_user_id],
          user_context: params[:user_context] || {},
          locale: params[:locale] || "en"
        )

        UsageLog.record_session!(current_company)
        session
      end

      def context_params
        params.require(:context).permit(:role, :team, :experience_level, :focus_area)
      end

      def message_json(message)
        {
          id: message.id,
          role: message.role,
          content: message.content,
          created_at: message.created_at.iso8601
        }
      end
    end
  end
end
