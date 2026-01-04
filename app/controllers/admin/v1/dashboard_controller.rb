# frozen_string_literal: true

module Admin
  module V1
    class DashboardController < BaseController
      def show
        render json: {
          company: company_summary,
          subscription: subscription_summary,
          usage_today: usage_for_date(Date.current),
          usage_this_week: usage_for_range(Date.current.beginning_of_week, Date.current),
          usage_this_month: usage_for_range(Date.current.beginning_of_month, Date.current)
        }
      end

      def usage
        start_date = parse_date(params[:start_date], 30.days.ago.to_date)
        end_date = parse_date(params[:end_date], Date.current)

        logs = current_company.usage_logs
          .for_date_range(start_date, end_date)
          .order(:date)

        render json: {
          period: { start_date: start_date, end_date: end_date },
          daily: logs.map { |log| usage_log_json(log) },
          summary: UsageLog.summary_for_period(current_company, start_date, end_date)
        }
      end

      private

      def company_summary
        {
          name: current_company.name,
          slug: current_company.slug,
          embed_key: current_company.embed_key,
          active: current_company.active,
          domains_count: current_company.embed_domains.active.count,
          total_sessions: current_company.chat_sessions.count
        }
      end

      def subscription_summary
        sub = current_company.subscription
        return { status: "none" } unless sub

        {
          status: sub.status,
          plan: sub.plan,
          current_period_end: sub.current_period_end&.iso8601,
          cancel_at_period_end: sub.cancel_at_period_end,
          days_until_renewal: sub.days_until_renewal
        }
      end

      def usage_for_date(date)
        log = current_company.usage_logs.find_by(date: date)
        return empty_usage if log.nil?

        usage_log_json(log)
      end

      def usage_for_range(start_date, end_date)
        UsageLog.summary_for_period(current_company, start_date, end_date)
      end

      def usage_log_json(log)
        {
          date: log.date,
          sessions_count: log.sessions_count,
          messages_count: log.messages_count,
          unique_users_count: log.unique_users_count,
          tokens_used: log.tokens_used
        }
      end

      def empty_usage
        {
          sessions_count: 0,
          messages_count: 0,
          unique_users_count: 0,
          tokens_used: 0
        }
      end

      def parse_date(date_string, default)
        return default if date_string.blank?

        Date.parse(date_string)
      rescue ArgumentError
        default
      end
    end
  end
end
