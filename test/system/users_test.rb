require "application_system_test_case"

class UsersTest < ApplicationSystemTestCase

  # /users
  test "visiting the index" do
    visit users_url
    assert_selector "h1", text: "Nicht gefunden"
  end
  
  # /user
  test "picking user" do
    visit '/user'
    assert_selector "h1", text: "Nicht gefunden"
  end
  
  # /users/new
  test "new user" do
    visit new_user_url
    assert_selector "h1", text: "Benutzereintrag anlegen"
  end
  
  # test ugly login "Ä Grüsel@öber.eu"
  test "special chars in login name" do
    @special_user = users(:special_user)
    visit login_url
    fill_in 'user_session_login', with: @special_user.login
    fill_in 'user_session_password', with: 'special_user_password'
    click_on 'Anmelden'
    check_page page, new_author_url, "h1", "Autor anlegen", 300
    get '/logout'
    check_page page, login_url, "h1", "Login", 300
  end

end
