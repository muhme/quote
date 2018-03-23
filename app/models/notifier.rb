class Notifier < ActionMailer::Base
  def deliver_password_reset_instructions(user)
    subject      "Kennwort für den Zitat-Service zurücksetzen"
    from         "heiko.luebbe@zitat-service.de"
    recipients   user.email
    content_type "text/html"
    sent_on      Time.now
    body         :edit_password_reset_url => edit_password_reset_url(user.perishable_token)
  end
end