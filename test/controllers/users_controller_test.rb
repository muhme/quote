require 'test_helper'

class UsersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @first_user = users(:first_user)
    @second_user = users(:second_user)
    # not as fixture, as this user has not to be created
    @changed_user = User.new()
    @changed_user.login = "changed_user"
    @changed_user.email = "change@somewhere.com"
  end

  # user list don't have to be available
  test "no index for non-registered" do
    get users_url
    assert_response :forbidden
  end

  test "no index for non-admins" do
    login :first_user
    get users_url
    assert_response :forbidden
  end

  test "index for admins" do
    login :admin_user
    get users_url
    assert_response :success
  end

  test "should get new" do
    get new_user_url
    assert_response :success
  end

  test "should create user" do
    assert_difference('User.count') do
      post users_url,
           params: { user: { login: "second", email: "second@bla.com", password: "123QWEasd",
                             password_confirmation: "123QWEasd" } }
    end
    assert_redirected_to root_url
    follow_redirect!
    assert_match(/A user .*second.* has been created for you./, @response.body)
  end

  test "failed to create new user without email address" do
    assert_no_difference('User.count') do
      post users_url,
           params: { user: { login: "test", email: "bla", password: "123QWEasd", password_confirmation: "123QWEasd" } }
    end
    assert_response :unprocessable_entity # 422
    assert_match(/Mail should look like an email address./, @response.body)
  end

  # user, e.g. /users/1/show
  test "not displaying user details ever" do
    get user_url id: @first_user
    assert_response :not_found
    login :first_user
    get user_url @first_user
    assert_response :not_found
    login :admin_user
    get user_url @first_user
    assert_response :not_found
  end

  test "not editing user entry w/o login" do
    get '/users/1/edit'
    assert_redirected_to root_url
    follow_redirect!
    assert_match(/Not logged in!/, @response.body)
  end

  test "should get edit" do
    login :first_user
    get '/users/current/edit'
    assert_match(/Update User Entry/, @response.body)
  end

  test "login" do
    login :first_user
    assert_redirected_to root_url
    follow_redirect!
    assert_match(/Hello first_user, nice to have you here./, @response.body)
  end

  test "failed login" do
    post user_sessions_url, :params => { :user_session => { :login => 'bla', :password => 'bli' } }
    assert_response :unprocessable_entity
    assert_match(/login is not valid/, @response.body)
  end

  test "own user update" do
    login :first_user
    patch user_url(@first_user),
          params: { user: { login: @changed_user.login, email: @changed_user.email, password: :changed_user_password,
                            password_confirmation: :changed_user_password } }
    assert_redirected_to root_url
    follow_redirect!
    assert_match(/Your user entry .*changed_user.* has been changed./, @response.body)
    get '/logout'
    login :changed_user
    assert_redirected_to root_url
    follow_redirect!
    assert_match(/Hello changed_user, nice to have you here./, @response.body)
  end

  test "failed own user change" do
    login :second_user
    assert_no_difference('User.count') do
      patch user_url(id: @second_user), params: { user: { email: @first_user.email } }
    end
    assert_response :unprocessable_entity # 422
    assert_match(/Mail has already been taken/, @response.body)
  end

  test "not logged-in try for user update" do
    patch user_url(id: @first_user),
          params: { user: { login: @changed_user.login, email: @changed_user.email, password: :changed_user_password,
                            password_confirmation: :changed_user_password } }
    assert_redirected_to root_url
    follow_redirect!
    assert_match(/Not logged in!/, @response.body)
    # and login is still possible with 1st user credentials
    login :first_user
    assert_redirected_to root_url
    follow_redirect!
    assert_match(/Hello first_user, nice to have you here./, @response.body)
  end

  test "destroy user not allowed" do
    delete '/users/1'
    assert_response :not_found
  end

  test "show avatar without params" do
    get users_show_avatar_url
    assert_redirected_to root_url
    follow_redirect!
    assert_match(/Parameters are missing/, @response.body)
  end

  test "show avatar with login param" do
    login :first_user
    get users_show_avatar_url, params: { login: users(:first_user).login }, as: :turbo_stream
    assert_response :success
  end

  test "show avatar with email param without Gravatar" do
    get users_show_avatar_url, params: { email: users(:first_user).email }, as: :turbo_stream
    assert_response :success
  end

  test "show avatar with email param with Gravatar" do
    get users_show_avatar_url, params: { email: users(:test_gravatar).email }, as: :turbo_stream
    assert_response :success
  end

  test "recreate avatar" do
    get users_recreate_avatar_url, as: :turbo_stream
    assert_response :success
  end

  test "take gravatar for existing" do
    get users_take_gravatar_url, params: { email: users(:test_gravatar).email }, as: :turbo_stream
    assert_response :success
  end

  test "take gravatar for non-existing" do
    get users_take_gravatar_url, params: { email: 'user.bla@non-existing.xyz' }, as: :turbo_stream
    assert_response :success
  end
end
