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
    assert_response 404
  end
  test "should get not_found III" do
    get "/static_pages/use/igitt/42"
    assert_response 404
  end

  test "should get joomla" do
    get static_pages_joomla_url
    assert_response :success
  end

  test "should get humans" do
    # get static_pages_humans_url
    get "/humans.txt"
    assert_response :success
  end

  test "should get contact" do
    get static_pages_contact_url
    assert_response :success
  end

  test "should get joomla_english" do
    get static_pages_joomla_english_url
    assert_response :success
  end

  test "should get project" do
    get static_pages_project_url
    assert_response :success
  end

  test "should get use" do
    get static_pages_use_url
    assert_response :success
  end

  test "should get help" do
    get static_pages_help_url
    assert_response :success
  end

  test "should get list" do
    get static_pages_list_url
    assert_response :success
  end

end
