require 'test_helper'

class UserMailerTest < ActionMailer::TestCase
  setup do
    @first_user = users(:first_user)
  end

  test "password_reset" do
    I18n.locale = "de"
    @first_user.reset_perishable_token!
    mail = UserMailer.password_reset(@first_user)
    assert_equal "Zurücksetzen des Passwortes", mail.subject
    assert_equal [@first_user.email], mail.to
    assert_equal ["heiko.luebbe@zitat-service.de"], mail.from
    assert_match "mit dem folgenden Link", mail.body.encoded
    assert_match @first_user.login, mail.body.encoded
    assert_match @first_user.perishable_token, mail.body.encoded
  end

  test "deliver_password_reset_instructions method" do
    assert_emails 1 do
      @first_user.deliver_password_reset_instructions!
    end
  end
end
