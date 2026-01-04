# frozen_string_literal: true

class DataRetentionCleanupJob < ApplicationJob
  queue_as :default

  def perform
    Company.find_each do |company|
      retention_days = company.settings["retention_days"].to_i
      next if retention_days.zero?

      cutoff_date = retention_days.days.ago

      deleted_sessions = company.chat_sessions.where("created_at < ?", cutoff_date).destroy_all
      deleted_logs = company.usage_logs.where("date < ?", cutoff_date.to_date).destroy_all

      if deleted_sessions.any? || deleted_logs.any?
        Rails.logger.info(
          "DataRetentionCleanup: Company #{company.id} - " \
          "Deleted #{deleted_sessions.count} sessions, #{deleted_logs.count} usage logs " \
          "(retention: #{retention_days} days)"
        )
      end
    end
  end
end
