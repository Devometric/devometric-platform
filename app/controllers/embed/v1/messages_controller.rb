# frozen_string_literal: true

module Embed
  module V1
    class MessagesController < BaseController
      include ActionController::Live

      before_action :set_chat_session

      def create
        content = message_params[:content]

        if params[:stream] == "true"
          stream_response(content)
        else
          sync_response(content)
        end
      rescue ::AI::CompanyChatService::ChatError => e
        Rails.logger.error("Chat error: #{e.message}")
        render json: { error: e.message }, status: :service_unavailable
      rescue ::AI::BaseClient::AuthenticationError => e
        Rails.logger.error("LLM API auth error: #{e.message}")
        render json: { error: "AI service not configured" }, status: :service_unavailable
      rescue ::AI::BaseClient::ConfigurationError => e
        Rails.logger.error("LLM configuration error: #{e.message}")
        render json: { error: e.message }, status: :service_unavailable
      rescue StandardError => e
        Rails.logger.error("Unexpected error in messages#create: #{e.class} - #{e.message}")
        Rails.logger.error(e.backtrace.first(10).join("\n"))
        render json: { error: "An unexpected error occurred" }, status: :internal_server_error
      end

      private

      def set_chat_session
        @chat_session = current_company.chat_sessions.find_by!(session_token: params[:session_token])
      end

      def message_params
        params.require(:message).permit(:content)
      end

      def sync_response(content)
        chat_service = ::AI::CompanyChatService.new(@chat_session)
        result = chat_service.send_message(content)

        render json: {
          message: message_json(result[:message]),
          usage: result[:usage]
        }
      end

      def stream_response(content)
        response.headers["Content-Type"] = "text/event-stream"
        response.headers["Cache-Control"] = "no-cache"
        response.headers["X-Accel-Buffering"] = "no"

        chat_service = ::AI::CompanyChatService.new(@chat_session)

        chat_service.send_message(content, stream: true) do |chunk, usage|
          if chunk
            response.stream.write("data: #{JSON.generate({ type: 'chunk', content: chunk })}\n\n")
          elsif usage
            response.stream.write("data: #{JSON.generate({ type: 'done', usage: usage })}\n\n")
          end
        end
      rescue IOError
        # Client disconnected
      ensure
        response.stream.close
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
