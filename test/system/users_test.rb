require "application_system_test_case"

class UsersTest < ApplicationSystemTestCase

  # /users
  test "visiting the index" do
    visit users_url
    assert_selector "h1", text: /Seite nicht gefunden.*404/
  end
  
  # /user
  test "picking user" do
    visit '/user'
    assert_selector "h1", text: /Seite nicht gefunden.*404/
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
    check_this_page page, "a", "Logout"
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
    check_this_page page, nil, "Login ist zu kurz"
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
    do_login
    check_this_page page, "a", "Logout"
  end
  
  # test ugly login "Ä Grüsel@öber.eu"
  test "special chars in login name" do
    special_user = users(:special_user)
    do_login special_user.login, :special_user_password
    check_page page, new_author_url, "h1", "Autor anlegen"
    visit logout_url
    check_page page, login_url, "h1", "Login"
  end
  
  test "not any details for authentication" do
    visit login_url
    click_on 'Anmelden'
    check_this_page page, nil, "Die Anmeldung war nicht erfolgreich!"
    check_this_page page, nil, "You did not provide any details for authentication"
  end

  test "password cannot be blank" do
    @first_user = users(:first_user)
    visit login_url
    fill_in 'user_session_login', with: @first_user.login
    click_on 'Anmelden'
    check_this_page page, nil, "Die Anmeldung war nicht erfolgreich!"
    check_this_page page, nil, "Password cannot be blank"
  end

  test "login is not valid" do
    do_login :bla, :bli, /Login/
    check_this_page page, nil, "Die Anmeldung war nicht erfolgreich!"
    check_this_page page, nil, "Login is not valid"
  end

  test "admin login" do
    do_login :admin_user, :admin_user_password
    check_this_page page, "h1", "Herzlich Willkommen beim Zitat-Service"
    assert page.has_css? "img[title='Administrator']"
  end

  # /users/1/edit
  test "change own login name" do
    do_login
    check_page page, 'users/current/edit', nil, "Benutzer-Eintrag aktualisieren"
    fill_in 'user_login', with: 'first_user_changed'
    click_on 'Speichern'
    check_this_page page, nil, "Dein Benutzereintrag „first_user_changed” wurde geändert."
    click_on 'Logout'
    do_login :first_user_changed
    check_this_page page, "a", "Logout"
  end
  test "change own password" do
    new_pw = "kheroij0245hf!"
    do_login
    check_page page, 'users/current/edit', nil, "Benutzer-Eintrag aktualisieren"
    fill_in 'user_password', with: new_pw 
    fill_in 'user_password_confirmation', with: "bruqher2reh+"
    click_on 'Speichern'
    check_this_page page, nil, /die Kennwörter stimmen nicht überein/
    fill_in 'user_password', with: new_pw 
    fill_in 'user_password_confirmation', with: new_pw
    click_on 'Speichern'
    check_this_page page, nil, "Dein Benutzereintrag „first_user” wurde geändert."
    do_login :first_user, new_pw
    check_this_page page, "a", "Logout"
  end

  test "cannot edit user without login" do
    visit edit_user_url(id: 1)
    check_this_page page, nil, "Nicht angemeldet!"
  end

  test "user edit error" do
    do_login
    check_page page, 'users/current/edit', nil, "Benutzer-Eintrag aktualisieren"
    fill_in 'user_login', with: ''
    click_on 'Speichern'
    check_this_page page, nil, "Login ist zu kurz"
  end

end
