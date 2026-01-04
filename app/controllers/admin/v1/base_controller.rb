# frozen_string_literal: true

module Admin
  module V1
    class BaseController < ActionController::API
      before_action :authenticate_company_admin!

      rescue_from ActiveRecord::RecordNotFound, with: :not_found
      rescue_from ActiveRecord::RecordInvalid, with: :unprocessable_entity
      rescue_from ActionController::ParameterMissing, with: :bad_request

      private

      def authenticate_company_admin!
        token = request.headers["Authorization"]&.split(" ")&.last
        return unauthorized unless token

        @current_admin = find_admin_by_token(token)
        unauthorized unless @current_admin
      end

      def find_admin_by_token(token)
        decoded = decode_jwt(token)
        return nil unless decoded

        CompanyAdmin.find_by(id: decoded["admin_id"])
      rescue StandardError
        nil
      end

      def decode_jwt(token)
        JWT.decode(token, jwt_secret, true, algorithm: "HS256").first
      rescue JWT::DecodeError
        nil
      end

      def encode_jwt(payload)
        JWT.encode(payload.merge(exp: 24.hours.from_now.to_i), jwt_secret, "HS256")
      end

      def jwt_secret
        Rails.application.credentials.secret_key_base || ENV.fetch("SECRET_KEY_BASE")
      end

      def current_admin
        @current_admin
      end

      def current_company
        @current_admin&.company
      end

      def unauthorized
        render json: { error: "Unauthorized" }, status: :unauthorized
      end

      def not_found
        render json: { error: "Not found" }, status: :not_found
      end

      def unprocessable_entity(exception)
        render json: { error: exception.record.errors.full_messages.join(", ") }, status: :unprocessable_entity
      end

      def bad_request(exception)
        render json: { error: exception.message }, status: :bad_request
      end
    end
  end
end
