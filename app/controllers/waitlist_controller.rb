# frozen_string_literal: true

class WaitlistController < ApplicationController
  skip_before_action :verify_authenticity_token, only: [:create]

  def create
    @waitlist_entry = WaitlistEntry.new(waitlist_params)

    respond_to do |format|
      if @waitlist_entry.save
        # Send welcome email
        WaitlistMailer.welcome_email(@waitlist_entry).deliver_later

        format.html { redirect_to root_path, notice: "You're on the list! Check your email for confirmation." }
        format.json { render json: { success: true, message: "You're on the list!" }, status: :created }
      else
        format.html { redirect_to root_path, alert: @waitlist_entry.errors.full_messages.first }
        format.json { render json: { success: false, errors: @waitlist_entry.errors.full_messages }, status: :unprocessable_entity }
      end
    end
  end

  private

  def waitlist_params
    params.require(:waitlist_entry).permit(:email, :company_name, :company_size, :use_case, :source)
  end
end
