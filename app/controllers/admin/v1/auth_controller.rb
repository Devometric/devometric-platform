# frozen_string_literal: true

module Admin
  module V1
    class AuthController < BaseController
      skip_before_action :authenticate_company_admin!, only: [:login, :register]

      def login
        admin = CompanyAdmin.find_by(email: auth_params[:email]&.downcase)

        if admin&.valid_password?(auth_params[:password])
          AuditLog.log!(
            company: admin.company,
            action: "admin_login",
            actor: admin,
            request: request
          )

          token = encode_jwt(admin_id: admin.id)
          render json: {
            token: token,
            admin: admin_json(admin)
          }
        else
          # Log failed attempts if we found an admin (helps detect brute force)
          if admin
            AuditLog.log!(
              company: admin.company,
              action: "admin_login_failed",
              actor: admin,
              request: request,
              metadata: { reason: "invalid_password" }
            )
          end

          render json: { error: "Invalid email or password" }, status: :unauthorized
        end
      end

      def register
        company = Company.new(company_params)
        admin = company.company_admins.build(admin_params.merge(role: "owner"))

        ActiveRecord::Base.transaction do
          company.save!
          admin.save!

          # Create trial subscription
          company.create_subscription!(
            plan: "b2b",
            status: "trialing",
            current_period_start: Time.current,
            current_period_end: 14.days.from_now
          )
        end

        token = encode_jwt(admin_id: admin.id)
        render json: {
          token: token,
          admin: admin_json(admin),
          company: company_json(company)
        }, status: :created
      rescue ActiveRecord::RecordInvalid => e
        render json: { error: e.record.errors.full_messages.join(", ") }, status: :unprocessable_entity
      end

      def logout
        # JWT tokens are stateless, so we just return success
        # Client should remove the token
        render json: { success: true }
      end

      def me
        render json: {
          admin: admin_json(current_admin),
          company: company_json(current_company)
        }
      end

      private

      def auth_params
        params.require(:auth).permit(:email, :password)
      end

      def company_params
        params.require(:company).permit(:name)
      end

      def admin_params
        params.require(:admin).permit(:name, :email, :password, :password_confirmation)
      end

      def admin_json(admin)
        {
          id: admin.id,
          email: admin.email,
          name: admin.name,
          role: admin.role
        }
      end

      def company_json(company)
        {
          id: company.id,
          name: company.name,
          slug: company.slug,
          embed_key: company.embed_key,
          active: company.active
        }
      end
    end
  end
end
