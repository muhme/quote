require 'test_helper'

class UsersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:first_user)
  end

  # user list don't have to be available
  test "should get index" do
    get users_url
    assert_response :missing
  end

  test "should get new" do
    get new_user_url
    assert_response :success
  end

# TODO commented out, as not working at the moment
#  test "should create user" do
#    assert_difference('User.count') do
#      post users_url, params: { user: { login: "second" } }
#    end
#
#    assert_redirected_to user_url(User.last)
#  end

  # TODO only own user
  test "should show user" do
    get user_url(@user)
    assert_response :success
  end

  # TODO only own user
  # test "should get edit" do
  #  get edit_user_url(@user)
  #  assert_response :success
  # end

  test "should update user" do
    patch user_url(@user), params: { user: { admin: @user.admin, crypted_password: @user.crypted_password, email: @user.email, login: @user.login, password_salt: @user.password_salt } }
    assert_redirected_to user_url(@user)
  end

  test "should destroy user" do
    assert_difference('User.count', -1) do
      delete user_url(@user)
    end

    assert_redirected_to users_url
  end
end
