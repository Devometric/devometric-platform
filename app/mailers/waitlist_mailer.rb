# frozen_string_literal: true

class WaitlistMailer < ApplicationMailer
  def welcome_email(waitlist_entry)
    @waitlist_entry = waitlist_entry
    @email = waitlist_entry.email

    mail(
      to: @email,
      subject: "You're on the Devometric waitlist!"
    )
  end
end
