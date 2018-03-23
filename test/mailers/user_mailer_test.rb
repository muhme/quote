require 'test_helper'

class UserMailerTest < ActionMailer::TestCase
  
  setup do
    @first_user = users(:first_user)
  end

  test "password_reset" do
    @first_user.reset_perishable_token!
    mail = UserMailer.password_reset(@first_user)
    assert_equal "Zurücksetzen des Kennwortes", mail.subject
    assert_equal [@first_user.email], mail.to
    assert_equal ["heiko.luebbe@zitat-service.de"], mail.from
    assert_match "mit dem folgenden Link", mail.body.encoded
    assert_match @first_user.login, mail.body.encoded
    # assert_match @first_user.persistence_token, mail.body.encoded
  end

end
