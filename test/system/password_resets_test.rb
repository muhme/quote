require "application_system_test_case"

class PasswordResetsTest < ApplicationSystemTestCase

  test "password reset page" do
    visit new_password_reset_url
    check_this_page page, "h1", "Reset password"
    # :de
    visit new_password_reset_url(locale: :de)
    check_this_page page, "h1", "Passwort zurücksetzen"
  end

  test "password reset page after login" do
    do_login
    check_this_page page, "a", "Logout"
    visit new_password_reset_url
    check_this_page page, "h1", "Reset password"
    # :de
    visit new_password_reset_url(locale: :de)
    check_this_page page, "h1", "Passwort zurücksetzen"
  end

  test "password reset link given" do
    do_login :bla, :bli, "Please register"
    check_this_page page, nil, "Login was not successful!"
    check_this_page page, nil, "Reset passwor"
    check_page_source page, /href=".*\/password_resets\/new/
  end

  # TODO fails on docker-machine as link is hard-coded zitat-service.de and needs to be set from $DOCKER_HOST
  test "password reset" do
    np = '348ZQHjdeqr+'
    visit new_password_reset_url
    fill_in 'email', with: 'first_user@whatever.com'
    click_on 'Send email'
    check_this_page page, nil, "An email with the password reset link has been sent to"
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
    click_on 'Set new password'
    check_this_page page, nil, 'The password for "first_user" has been successfully updated.'
    click_on 'Logout'
    do_login :first_user, np
    check_page page, root_url, "a", "Logout"
  end

  test "password reset unknown email" do
    visit new_password_reset_url
    fill_in 'email', with: 'bla'
    click_on 'Send email'
    check_this_page page, nil, "No user found with the email"
  end

end
