# frozen_string_literal: true

module Admin
  module V1
    class SecurityController < BaseController
      # GET /admin/v1/security
      def show
        render json: {
          retention_days: current_company.settings["retention_days"] || 0,
          data_stats: {
            chat_sessions_count: current_company.chat_sessions.count,
            messages_count: current_company.chat_sessions.joins(:messages).count,
            oldest_session: current_company.chat_sessions.minimum(:created_at),
            total_tokens_used: current_company.usage_logs.sum(:tokens_used)
          }
        }
      end

      # PATCH /admin/v1/security
      def update
        old_settings = current_company.settings.dup
        settings = current_company.settings.merge(security_params.to_h)
        current_company.update!(settings: settings)

        AuditLog.log!(
          company: current_company,
          action: "security_settings_update",
          actor: current_company_admin,
          request: request,
          metadata: {
            old_retention_days: old_settings["retention_days"],
            new_retention_days: settings["retention_days"]
          }
        )

        render json: {
          success: true,
          retention_days: current_company.settings["retention_days"]
        }
      end

      # POST /admin/v1/security/export
      def export
        format = params[:format] || "json"

        AuditLog.log!(
          company: current_company,
          action: "data_export",
          actor: current_company_admin,
          request: request,
          metadata: {
            format: format,
            chat_sessions_count: current_company.chat_sessions.count,
            messages_count: current_company.chat_sessions.joins(:messages).count
          }
        )

        export_data = {
          company: company_export_data,
          chat_sessions: chat_sessions_export_data,
          usage_logs: usage_logs_export_data,
          exported_at: Time.current.iso8601
        }

        case format
        when "csv"
          render_csv_export(export_data)
        else
          render json: export_data
        end
      end

      # DELETE /admin/v1/security/data
      def destroy_data
        scope = params[:scope] || "all"
        older_than_days = params[:older_than_days]&.to_i

        # Count records before deletion for audit
        records_to_delete = count_records_to_delete(scope, older_than_days)

        case scope
        when "chat_sessions"
          destroy_chat_sessions(older_than_days)
        when "usage_logs"
          destroy_usage_logs(older_than_days)
        when "all"
          destroy_all_data(older_than_days)
        else
          return render json: { error: "Invalid scope" }, status: :unprocessable_entity
        end

        AuditLog.log!(
          company: current_company,
          action: "data_delete",
          actor: current_company_admin,
          request: request,
          metadata: {
            scope: scope,
            older_than_days: older_than_days,
            records_deleted: records_to_delete
          }
        )

        render json: {
          success: true,
          message: "Data deletion initiated",
          scope: scope,
          older_than_days: older_than_days
        }
      end

      private

      def security_params
        params.require(:security).permit(:retention_days)
      end

      def count_records_to_delete(scope, older_than_days)
        counts = {}

        if scope.in?(%w[chat_sessions all])
          sessions = current_company.chat_sessions
          sessions = sessions.where("created_at < ?", older_than_days.days.ago) if older_than_days.present?
          counts[:chat_sessions] = sessions.count
          counts[:messages] = Message.where(chat_session_id: sessions.select(:id)).count
        end

        if scope.in?(%w[usage_logs all])
          logs = current_company.usage_logs
          logs = logs.where("date < ?", older_than_days.days.ago.to_date) if older_than_days.present?
          counts[:usage_logs] = logs.count
        end

        counts
      end

      def company_export_data
        {
          id: current_company.id,
          name: current_company.name,
          slug: current_company.slug,
          created_at: current_company.created_at.iso8601,
          settings: current_company.settings.except("retention_days"),
          system_prompt: current_company.system_prompt,
          policies: current_company.policies,
          coding_standards: current_company.coding_standards,
          work_culture: current_company.work_culture,
          tech_stack: current_company.tech_stack
        }
      end

      def chat_sessions_export_data
        current_company.chat_sessions.includes(:messages).map do |session|
          {
            id: session.id,
            external_user_id: session.external_user_id,
            created_at: session.created_at.iso8601,
            messages: session.messages.map do |msg|
              {
                role: msg.role,
                content: msg.content,
                tokens_used: msg.tokens_used,
                created_at: msg.created_at.iso8601
              }
            end
          }
        end
      end

      def usage_logs_export_data
        current_company.usage_logs.map do |log|
          {
            date: log.date.iso8601,
            sessions_count: log.sessions_count,
            messages_count: log.messages_count,
            unique_users_count: log.unique_users_count,
            tokens_used: log.tokens_used
          }
        end
      end

      def render_csv_export(export_data)
        csv_data = generate_csv(export_data)
        send_data csv_data,
                  filename: "road_to_native_export_#{Date.current}.csv",
                  type: "text/csv"
      end

      def generate_csv(export_data)
        require "csv"

        CSV.generate do |csv|
          csv << ["Export Date", export_data[:exported_at]]
          csv << []

          csv << ["Chat Sessions"]
          csv << %w[SessionID UserID CreatedAt MessageRole MessageContent TokensUsed]
          export_data[:chat_sessions].each do |session|
            session[:messages].each do |msg|
              csv << [
                session[:id],
                session[:external_user_id],
                session[:created_at],
                msg[:role],
                msg[:content]&.truncate(500),
                msg[:tokens_used]
              ]
            end
          end
        end
      end

      def destroy_chat_sessions(older_than_days)
        sessions = current_company.chat_sessions
        sessions = sessions.where("created_at < ?", older_than_days.days.ago) if older_than_days.present?
        sessions.destroy_all
      end

      def destroy_usage_logs(older_than_days)
        logs = current_company.usage_logs
        logs = logs.where("date < ?", older_than_days.days.ago.to_date) if older_than_days.present?
        logs.destroy_all
      end

      def destroy_all_data(older_than_days)
        destroy_chat_sessions(older_than_days)
        destroy_usage_logs(older_than_days)
      end
    end
  end
end
