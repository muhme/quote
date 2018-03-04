require 'test_helper'

class UsersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @first_user = users(:first_user)
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

  # user, e.g. /users/1/show
  test "not displaying user details ever" do
    get user_url(@first_user)
    assert_response :not_found
    login :first_user
    get user_url(@first_user)
    assert_response :not_found
    login :admin_user
    get user_url(@first_user)
    assert_response :not_found
  end

  # TODO only own user
  # test "should get edit" do
  #  get edit_user_url(@user)
  #  assert_response :success
  # end

# TODO make useful
#  test "should update user" do
#    patch user_url(@first_user), params: { user: { admin: @user.admin, crypted_password: @user.crypted_password, email: @user.email, login: @user.login, password_salt: @user.password_salt } }
#    assert_redirected_to user_url(@user)
#  end

  test "destroy user not allowed" do
    delete '/users/1'
    assert_response :not_found
  end

end
