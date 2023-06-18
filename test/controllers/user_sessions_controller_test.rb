require 'test_helper'

class UserSessionsControllerTest < ActionDispatch::IntegrationTest

  test "new" do
    get new_user_session_url
    assert_response :success
  end

  test "login successful" do
    I18n.available_locales.each do |locale|
      post user_sessions_url(locale: locale), params: { user_session: { login: "first_user", password: "first_user_password" } }
      assert_redirected_to root_path(locale: locale)
      follow_redirect!
      assert_response :success
      assert_match(/Hello first_user, nice to have you here./i, @response.body)   if locale == :en
      assert_match(/Hallo first_user, schön dass Du da bist./i, @response.body)   if locale == :de
      assert_match(/Hola first_user, es un gusto tenerte aquí./i, @response.body) if locale == :es
      assert_match(/こんにちは first_user、おかえりなさい。/i, @response.body)         if locale == :ja
      assert_match(/Вітаємо first_user, раді бачити вас тут./i, @response.body)   if locale == :uk
      get logout_url
    end
  end

  test "login failed" do
    post user_sessions_url, params: { locale: :en, user_session: { login: "first_user", password: "" } }
    assert_response :unprocessable_entity # 422
    assert_match /1 error/i, @response.body
    assert_match /password can not be blank/i, @response.body

    post user_sessions_url, params: { locale: :en, user_session: { login: "first_user", password: "bla" } }
    assert_response :unprocessable_entity # 422
    assert_match /1 error/i, @response.body
    assert_match /password is not valid/i, @response.body
  end

  test "logout" do
    login :first_user
    assert_redirected_to root_path(locale: I18n.locale)
    get new_author_url
    assert_response :success
    get logout_url
    assert_redirected_to new_user_session_url
    get new_author_url
    assert_forbidden
  end

end
