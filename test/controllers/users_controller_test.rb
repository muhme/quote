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

  test "should create user" do
    assert_difference('User.count') do
      post users_url, params: { user: { login: "second", email: "second@bla.com" , password: "123QWEasd", password_confirmation: "123QWEasd" } }
    end

    assert_redirected_to root_url
  end

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

  test "should get edit" do
    get edit_user_url(@first_user)
    assert_redirected_to root_url
  end

  test "should update user" do
    patch user_url(@first_user), params: { user: { login: "first+", email: "first_plus@bla.com" , password: "123QWEasd", password_confirmation: "123QWEasd" } }
    assert_redirected_to root_url
  end

  test "destroy user not allowed" do
    delete '/users/1'
    assert_response :not_found
  end

end
