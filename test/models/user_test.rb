require 'test_helper'

class UserTest < ActiveSupport::TestCase
  
  def setup
    @user = User.find_by_login(:first_user)
    activate_authlogic
  end
  
  test "validate setup" do
    assert @user.valid?
  end
  
  test "user's login should not be empty" do
    @user.login = ""
    assert_not @user.valid?
  end
  
  test "user's email should not be empty" do
    @user.email = ""
    assert_not @user.valid?
  end

  test "user's login, email, crypted_password and password_salt max length" do
    @user.login = "a" * 32
    @user.email = "@bla.de"
    @user.email = "a" * (64 - @user.email.length) + @user.email # have to look like an email address
    @user.crypted_password = "a" * 255
    @user.password_salt = "a" * 32
    assert @user.valid?
  end
  
  test "user's login have to be unique" do
    @user.save
    duplicate = @user.dup
    duplicate.email = "fresh@unused.com"
    assert_not duplicate.valid?
  end
  test "user's login have to be unique case insensitive" do
    @user.save
    duplicate = @user.dup
    duplicate.email = "fresh@unused.com"
    duplicate.login = duplicate.login.upcase 
    assert_not duplicate.valid?
  end
  test "user's login should not be too long" do
    @user.login = "a" * 33
    assert_not @user.valid?
  end
 
  test "user's email have to be unique" do
    @user.save
    duplicate = @user.dup
    duplicate.login = "fresh_and_unused"
    assert_not duplicate.valid?
  end
  test "user's email have to be unique case insensitive" do
    @user.save
    duplicate = @user.dup
    duplicate.login = "fresh_and_unused"
    duplicate.email = duplicate.email.upcase 
    assert_not duplicate.valid?
  end
  test "user's email should not be too long" do
    @user.email = "a" * 65
    assert_not @user.valid?
  end
  
  test "user's crypted_password should not be too long" do
    @user.crypted_password = "a" * 256
    assert_not @user.valid?
  end
  test "password_salt should not be too long" do
    @user.password_salt = "a" * 256
    assert_not @user.valid?
  end
  test "non-ascii character, but UTF8 letter in login name" do
    @user.login = "lübbe"
    assert @user.valid?
  end
  test "non-ascii character, but UTF8 letter in email address" do
    @user.email = "heiko.lübbe@somewhere.de"
    assert @user.valid?
  end
  test "@ char needed in email address" do
    @user.email = "bla"
    assert_not @user.valid?
  end
  test "spaces in login name are possible" do
    @user.login = "james bond"
    assert @user.valid?
  end
  test "user's admin defaults to false" do
    @user.save
    assert @user.admin == false
  end
end
