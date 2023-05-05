require "application_system_test_case"

class PasswordResetsTest < ApplicationSystemTestCase

  test "password reset page" do
    visit new_password_reset_url
    # TODO check_this_page page, "h1", "Passwort zurücksetzen"
    check_this_page page, nil, "Passwort zurücksetzen"
  end

  test "password reset page with login" do
    do_login
    check_this_page page, "a", "Logout"
    visit new_password_reset_url
    # this have to force logout
    check_this_page page, "a", "Login"
    # TODO check_this_page page, "h1", "Passwort zurücksetzen"
    check_this_page page, nil, "Passwort zurücksetzen"
  end

  test "password reset link given" do
    do_login :bla, :bli, /Bitte melde Dich an/
    check_this_page page, nil, "Fehler bei der Anmeldung!"
    check_this_page page, nil, "Passwort zurücksetzen"
    check_page_source page, /href=".*\/password_resets\/new/
  end

  # TODO fails on docker-machine as link is hard-coded zitat-service.de and needs to be set from $DOCKER_HOST
  test "password reset" do
    np = '348ZQHjdeqr+'
    visit new_password_reset_url
    fill_in 'email', with: 'first_user@whatever.com'
    click_on 'E-Mail schicken'
    check_this_page page, nil, /Eine E-Mail mit dem Link zum Zurücksetzen des Passworts wurde an .* gesendet./
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
    click_on 'Neues Passwort setzen'
    check_this_page page, nil, /Das Passwort für .* wurde erfolgreich aktualisiert./
    click_on 'Logout'
    do_login :first_user, np
    check_page page, root_url, "a", "Logout"
  end

  test "password reset unknown email" do
    visit new_password_reset_url
    fill_in 'email', with: 'bla'
    click_on 'E-Mail schicken'
    check_this_page page, nil, /Kein Benutzer mit der E-Mail .* gefunden!/
  end

end
