# frozen_string_literal: true

module Admin
  module V1
    class ChatSessionsController < BaseController
      def index
        sessions = current_company.chat_sessions
          .includes(:messages)
          .order(created_at: :desc)
          .page(params[:page])
          .per(params[:per_page] || 20)

        render json: {
          sessions: sessions.map { |s| session_summary_json(s) },
          pagination: pagination_json(sessions)
        }
      end

      def show
        session = current_company.chat_sessions.find(params[:id])
        messages = session.messages.ordered

        render json: {
          session: session_detail_json(session),
          messages: messages.map { |m| message_json(m) }
        }
      end

      private

      def session_summary_json(session)
        {
          id: session.id,
          session_token: session.session_token,
          external_user_id: session.external_user_id,
          locale: session.locale,
          message_count: session.messages.count,
          started_at: session.started_at&.iso8601,
          ended_at: session.ended_at&.iso8601,
          last_message_at: session.last_message_at&.iso8601
        }
      end

      def session_detail_json(session)
        {
          id: session.id,
          session_token: session.session_token,
          external_user_id: session.external_user_id,
          user_context: session.user_context,
          locale: session.locale,
          started_at: session.started_at&.iso8601,
          ended_at: session.ended_at&.iso8601,
          created_at: session.created_at.iso8601
        }
      end

      def message_json(message)
        {
          id: message.id,
          role: message.role,
          content: message.content,
          tokens_used: message.tokens_used,
          created_at: message.created_at.iso8601
        }
      end

      def pagination_json(collection)
        {
          current_page: collection.current_page,
          total_pages: collection.total_pages,
          total_count: collection.total_count,
          per_page: collection.limit_value
        }
      end
    end
  end
end
