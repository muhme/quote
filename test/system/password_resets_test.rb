require "application_system_test_case"

class PasswordResetsTest < ApplicationSystemTestCase

  test "password reset page" do
    visit new_password_reset_url
    # TODO check_this_page page, "h1", "Kennwort zurücksetzen"
    check_this_page page, nil, "Kennwort zurücksetzen"
  end

  test "password reset page with login" do
    visit login_url
    fill_in 'user_session_login', with: 'first_user'
    fill_in 'user_session_password', with: 'first_user_password'
    click_on 'Anmelden'
    check_this_page page, "a", "Logout"
    visit new_password_reset_url
    # this have to force logout
    check_this_page page, "a", "Login"
    # TODO check_this_page page, "h1", "Kennwort zurücksetzen"
    check_this_page page, nil, "Kennwort zurücksetzen"
  end

  test "password reset link given" do
    visit login_url
    fill_in 'user_session_login', with: 'bla'
    fill_in 'user_session_password', with: 'bli'
    click_on 'Anmelden'
    check_this_page page, nil, '<a href="password_resets/new"'
  end

  test "password reset" do
    np = '348ZQHjdeqr+'
    visit new_password_reset_url
    fill_in 'email', with: 'first_user@whatever.com'
    click_on 'Email schicken'
    check_this_page page, nil, "Eine E-Mail mit dem Link zum Zurücksetzen des Kennwortes wurde an .* geschickt."
    # do it
    last_email = ActionMailer::Base.deliveries.last
    #    <a href=3D"http://zitat-service.de/password_resets/V6mb1Fjyd4e7B_d4DAw=
    #    8/edit?login=3Dfirst_user">http://zitat-service.de/password_resets/V6mb1F=
    # /password_resets/V6mb1Fjyd4e7B_d4DAw8
    pt = last_email.body.encoded.sub(/.*(\/password_resets\/[^\/]+).*/m, '\1').sub(/=[\s]/, '')
    url = pt + "/edit?login=first_user"
    visit url
    fill_in 'password', with: np
    fill_in 'password_confirmation', with: np
    click_on 'Kennwort aktualisieren'
    check_this_page page, nil, "Das Kennwort für .* wurde erfolgreich aktualisiert."
    click_on 'Logout'
    click_on 'Login'
    fill_in 'user_session_login', with: 'first_user'
    fill_in 'user_session_password', with: np
    click_on 'Anmelden'
    check_page page, root_url, "a", "Logout"
  end

  test "password reset unknown email" do
    visit new_password_reset_url
    fill_in 'email', with: 'bla'
    click_on 'Email schicken'
    check_this_page page, nil, "Es wurde kein Benutzer mit der Email-Adresse .* gefunden!."
  end

end
