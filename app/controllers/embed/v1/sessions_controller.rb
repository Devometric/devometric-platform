# frozen_string_literal: true

module Embed
  module V1
    class SessionsController < BaseController
      before_action :set_chat_session, only: [:history, :update_context]

      def resume
        existing_session = find_and_verify_existing_session
        is_new_session = existing_session.nil?
        session = existing_session || create_new_session

        response_data = {
          session_token: session.session_token,
          messages: session.messages.ordered.map { |m| message_json(m) },
          is_new_session: is_new_session
        }

        # Only return session_secret for new sessions
        # Client must securely store this for future session resumption
        response_data[:session_secret] = session.session_secret if is_new_session

        render json: response_data
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

      # SECURITY FIX: Require session_secret to resume existing sessions
      # This prevents attackers from hijacking sessions by guessing external_user_id values
      def find_and_verify_existing_session
        return nil if params[:external_user_id].blank?

        session = current_company.chat_sessions
          .where(external_user_id: params[:external_user_id])
          .where(ended_at: nil)
          .order(created_at: :desc)
          .first

        return nil unless session

        # If session exists but no secret provided, reject resumption
        provided_secret = params[:session_secret]
        if provided_secret.blank?
          Rails.logger.warn(
            "[Security] Session resumption rejected: missing session_secret for " \
            "external_user_id=#{params[:external_user_id]} from IP #{request.remote_ip}"
          )
          return nil
        end

        # Verify the provided secret matches
        unless session.verify_secret(provided_secret)
          Rails.logger.warn(
            "[Security] Session resumption rejected: invalid session_secret for " \
            "external_user_id=#{params[:external_user_id]} from IP #{request.remote_ip}"
          )
          return nil
        end

        session
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
