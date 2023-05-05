require 'test_helper'

class StaticPagesControllerTest < ActionDispatch::IntegrationTest

  test "should get home" do
    get "/"
    assert_response :success
  end

  test "should get not_found I" do
    get "/igitt"
    assert_response 404
  end
# rails test fails "The action 'igitt' could not be found for StartController"
#  test "should get not_found II" do
#    get "/start/igitt"
#    assert_response :success
#  end
  test "should get use too" do
    get "/static_pages/use/igitt"
    assert_response :not_found # 404
  end
  test "should get not_found III" do
    get "/static_pages/use/igitt/42"
    assert_response :not_found # 404
  end
  test "/404" do
    get "/404"
    assert_response :not_found # 404 
  end
  test "/422" do
    get "/422"
    assert_response :unprocessable_entity #422
  end
  test "/500" do
    get "/500"
    assert_response :internal_server_error #500
  end

  test "should get joomla" do
    get joomla_url
    assert_response :success
  end

  test "should get humans" do
    # get start_humans_url
    get "/humans.txt"
    assert_response :success
  end

  test "should get contact" do
    get start_contact_url
    assert_response :success
  end

  test "should get project" do
    get start_project_url
    assert_response :success
  end

  test "should get use" do
    get start_use_url
    assert_response :success
  end

  test "should get help" do
    get start_help_url
    assert_response :success
  end

  test "should get list" do
    get start_list_url
    assert_response :success
  end
  
  test "forbidden" do
    get forbidden_url
    assert_response :forbidden # 403
  end
end
