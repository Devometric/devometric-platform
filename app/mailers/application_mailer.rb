class ApplicationMailer < ActionMailer::Base
  default from: ENV.fetch("MAILER_FROM", "Devometric <info@devometric.com>")
  layout "mailer"
end
