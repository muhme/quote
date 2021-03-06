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
    fill_in 'user_login', with: 'one'
    fill_in 'user_email', with: 'one@somewhere.com'
    fill_in 'user_password', with: 'abcDEF78'
    fill_in 'user_password_confirmation', with: 'abcDEF78'
    click_on 'Speichern'
    check_page page, root_url, "a", "Logout"
  end
  test "new user error email address" do
    visit new_user_url
    assert_selector "h1", text: "Benutzereintrag anlegen"
    fill_in 'user_login', with: 'two'
    fill_in 'user_email', with: 'two'
    fill_in 'user_password', with: 'abcDEF78'
    fill_in 'user_password_confirmation', with: 'abcDEF78'
    click_on 'Speichern'
    check_this_page page, nil, "Email should look like an email address."
  end
  test "login is too short" do
    visit new_user_url
    assert_selector "h1", text: "Benutzereintrag anlegen"
    fill_in 'user_login', with: 'on'
    fill_in 'user_email', with: 'one@somewhere.com'
    fill_in 'user_password', with: 'abcDEF78'
    fill_in 'user_password_confirmation', with: 'abcDEF78'
    click_on 'Speichern'
    check_this_page page, nil, "Login is too short"
  end
  test "login should use letters" do
    visit new_user_url
    assert_selector "h1", text: "Benutzereintrag anlegen"
    fill_in 'user_login', with: '==='
    fill_in 'user_email', with: 'one@somewhere.com'
    fill_in 'user_password', with: 'abcDEF78'
    fill_in 'user_password_confirmation', with: 'abcDEF78'
    click_on 'Speichern'
    check_this_page page, nil, "Login should use only letters, numbers, spaces"
  end

  test "login" do
    @first_user = users(:first_user)
    visit login_url
    fill_in 'user_session_login', with: @first_user.login
    fill_in 'user_session_password', with: 'first_user_password'
    click_on 'Anmelden'
    check_page page, root_url, "a", "Logout"
  end
  
  # test ugly login "Ä Grüsel@öber.eu"
  test "special chars in login name" do
    @special_user = users(:special_user)
    visit login_url
    fill_in 'user_session_login', with: @special_user.login
    fill_in 'user_session_password', with: 'special_user_password'
    click_on 'Anmelden'
    check_page page, new_author_url, "h1", "Autor anlegen"
    visit logout_url
    check_page page, login_url, "h1", "Login"
  end
  
  test "not any details for authentication" do
    visit login_url
    click_on 'Anmelden'
    check_page page, root_url, nil, "Die Anmeldung war nicht erfolgreich!.*You did not provide any details for authentication."
  end

  test "password cannot be blank" do
    @first_user = users(:first_user)
    visit login_url
    fill_in 'user_session_login', with: @first_user.login
    click_on 'Anmelden'
    check_page page, root_url, nil, "Die Anmeldung war nicht erfolgreich!.*Password cannot be blank"
  end

  test "login is not valid" do
    visit login_url
    fill_in 'user_session_login', with: 'bla'
    fill_in 'user_session_password', with: 'bli'
    click_on 'Anmelden'
    check_this_page page, nil, "Die Anmeldung war nicht erfolgreich!.*Login is not valid"
  end

  test "admin login" do
    @admin_user = users(:admin_user)
    visit login_url
    fill_in 'user_session_login', with: @admin_user.login
    fill_in 'user_session_password', with: 'admin_user_password'
    click_on 'Anmelden'
    check_this_page page, nil, 'title="Administrator"'
  end

  # /users/1/edit
  test "change own login" do
    visit login_url
    fill_in 'user_session_login', with: 'first_user'
    fill_in 'user_session_password', with: 'first_user_password'
    click_on 'Anmelden'
    check_page page, 'users/current/edit', nil, "Benutzer-Eintrag aktualisieren"
    fill_in 'user_login', with: 'first_user_changed'
    click_on 'Speichern'
    check_this_page page, nil, "Benutzereintrag wurde geändert."
    click_on 'Logout'
    click_on 'Login'
    fill_in 'user_session_login', with: 'first_user_changed'
    fill_in 'user_session_password', with: 'first_user_password'
    click_on 'Anmelden'
    check_page page, root_url, "a", "Logout"
  end

  test "cannot edit user without login" do
    visit edit_user_url(1)
    check_this_page page, nil, "Nicht angemeldet!"
  end

  test "user edit error" do
    visit login_url
    fill_in 'user_session_login', with: 'first_user'
    fill_in 'user_session_password', with: 'first_user_password'
    click_on 'Anmelden'
    check_page page, 'users/current/edit', nil, "Benutzer-Eintrag aktualisieren"
    fill_in 'user_login', with: ''
    click_on 'Speichern'
    check_this_page page, nil, "Login is too short"
  end

end
