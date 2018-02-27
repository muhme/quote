require 'test_helper'

class UserTest < ActiveSupport::TestCase
  
  def setup
    @user = User.find_by_login('one')
    @user.password = "12345678" # TODO only set to run test, useless
    @user.password_confirmation = "12345678" # TODO only set to run test, useless
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
    assert_not duplicate.valid?
  end
  
  test "user's login should not be too long" do
    @user.login = "a" * 33
    assert_not @user.valid?
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
    @user.password_salt = "a" * 33
    assert_not @user.valid?
  end
  
  test "user's admin defaults to false" do
    @user.save
    assert @user.admin == false
  end
end
