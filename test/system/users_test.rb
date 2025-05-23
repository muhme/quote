require "application_system_test_case"

class UsersTest < ApplicationSystemTestCase
  # /users
  test "not possible to visit the user index w/o login" do
    visit root_url
    assert_no_selector "a[href='#{users_path(locale: :en)}']"
    visit users_path
    assert_selector "h1", text: /Access Denied .* 403/
    check_this_page page, nil, "Not an Administrator!"
  end
  test "not possible to visit the user index as non-admin" do
    do_login
    visit root_url
    assert_no_selector "a[href='#{users_path(locale: :en)}']"
    visit users_path
    assert_selector "h1", text: /Access Denied .* 403/
    check_this_page page, nil, "Not an Administrator!"
  end
  test "visiting the user index as admin" do
    do_login :admin_user, :admin_user_password
    visit root_url
    assert_selector "a[href='#{users_path(locale: :en)}']"
    click_link "User", href: users_path(locale: :en)
    # don't use check_page as it takes e.g. 1.5 seconds on Docker container
    visit users_path
    check_this_page page, "h1", "User Entries with Quotes"
  end

  # /user
  test "picking user" do
    visit '/user'
    assert_selector "h1", text: /Page not found .* 404/
  end

  # /users/new
  test "new user" do
    visit new_user_url
    assert_selector "h1", text: "Create User Entry"
    fill_in 'user_login', with: 'one'
    fill_in 'user_email', with: 'one@somewhere.com'
    check_this_page page, nil, "Avatar was created automatically."
    fill_in 'user_password', with: 'abcDEF78'
    fill_in 'user_password_confirmation', with: 'abcDEF78'
    click_on 'Save'
    check_this_page page, "a", "Logout"
  end
  test "new user error email address" do
    visit new_user_url
    assert_selector "h1", text: "Create User Entry"
    fill_in 'user_login', with: 'two'
    fill_in 'user_email', with: 'two'
    fill_in 'user_password', with: 'abcDEF78'
    fill_in 'user_password_confirmation', with: 'abcDEF78'
    click_on 'Save'
    check_this_page page, nil, "Mail should look like an email address"
  end
  test "login is too short" do
    visit new_user_url
    assert_selector "h1", text: "Create User Entry"
    fill_in 'user_login', with: 'on'
    fill_in 'user_email', with: 'one@somewhere.com'
    fill_in 'user_password', with: 'abcDEF78'
    fill_in 'user_password_confirmation', with: 'abcDEF78'
    click_on 'Save'
    check_this_page page, nil, "Username is too short (at least 3 characters)"
  end
  test "login should use letters" do
    visit new_user_url
    assert_selector "h1", text: "Create User Entry"
    fill_in 'user_login', with: '==='
    fill_in 'user_email', with: 'one@somewhere.com'
    fill_in 'user_password', with: 'abcDEF78'
    fill_in 'user_password_confirmation', with: 'abcDEF78'
    click_on 'Save'
    check_this_page page, nil, "Username should use only letters, numbers, spaces, and .-_@+"
  end

  test "login" do
    do_login
    check_this_page page, "a", "Logout"
  end

  # test ugly login "Ä Grüsel@öber.eu"
  test "special chars in login name" do
    special_user = users(:special_user)
    do_login special_user.login, :special_user_password
    check_page page, new_author_url, "h1", "Author create"
    visit logout_url
    check_page page, login_url, "h1", "Please register"
  end

  # no more testable, as the browser shows error for empty login and password with <input autocomplete="...
  # test "not any details for authentication" do
  #   visit login_url
  #   click_on 'Log In'
  #   check_this_page page, nil, "Login was not successful!"
  #   check_this_page page, nil, "You did not provide any details for authentication."
  # end

  # no more testable, as the browser shows error for empty password with <input autocomplete="...
  # test "password cannot be blank" do
  #   @first_user = users(:first_user)
  #   visit login_url
  #   fill_in 'user_session_login', with: @first_user.login
  #   click_on 'Log In'
  #   check_this_page page, nil, "Login was not successful!"
  #   check_this_page page, nil, "password can not be blank"
  # end

  test "login is not valid" do
    do_login :bla, :bli, /Please register/
    check_this_page page, nil, "Login was not successful!"
    check_this_page page, nil, "login is not valid"
  end

  test "admin login" do
    do_login :admin_user, :admin_user_password
    check_this_page page, "h1", "Welcome to the quote service zitat-service.de"
    assert page.has_css? "img[title='Administrator']"
  end

  # /users/1/edit
  test "change own login name" do
    fuc = "first_user_changed"
    do_login
    check_page page, 'users/current/edit', nil, "Update User Entry"
    fill_in 'user_login', with: fuc
    click_on 'Save'
    check_this_page page, nil, "Your user entry \"#{fuc}\" has been changed."
    click_on 'Logout'
    do_login fuc
    check_this_page page, "a", "Logout"
  end
  test "change own password" do
    new_pw = "kheroij0245hf!"
    do_login
    check_page page, 'users/current/edit', nil, "Update User Entry"
    fill_in 'user_password', with: new_pw
    fill_in 'user_password_confirmation', with: "bruqher2reh+"
    click_on 'Save'
    check_this_page page, nil, /Password confirmation doesn't match password/
    fill_in 'user_password', with: new_pw
    fill_in 'user_password_confirmation', with: new_pw
    click_on 'Save'
    check_this_page page, nil, 'Your user entry "first_user" has been changed.'
    do_login :first_user, new_pw
    check_this_page page, "a", "Logout"
  end

  test "cannot edit user without login" do
    visit edit_user_url(id: 1)
    check_this_page page, nil, "Not logged in!"
  end

  test "user edit error" do
    do_login
    check_page page, 'users/current/edit', nil, "Update User Entry"
    # use one letter, as empty string is no more possible as the browser shows error with <input autocomplete="...
    fill_in 'user_login', with: 'a'
    click_on 'Save'
    check_this_page page, nil, "Username is too short (at least 3 characters)"
  end

  test "recreate user avater" do
    # as public/images/ta/1.png is under git control and recreate avatar is overwriting with random color,
    # we have to use test_gravatar user as 6.png is not under git control
    do_login users(:test_gravatar).login, "#{users(:test_gravatar).login}_password"
    check_page page, 'users/current/edit', nil, "Update User Entry"
    click_on 'Recreate'
    check_this_page page, nil, "Avatar was created with a random color"
    click_on 'Save'
    check_this_page page, nil, "Your user entry \"#{users(:test_gravatar).login}\" has been changed."
  end
  test "recreate users Gravatar" do
    do_login users(:test_gravatar).login, "#{users(:test_gravatar).login}_password"
    visit edit_user_url(id: users(:test_gravatar).id)
    # first overwrite with recreated avatar
    click_on 'Recreate'
    check_this_page page, nil, "Avatar was created with a random color"
    # 2nd recreate from Gravater
    click_on 'Copy Gravatar'
    check_this_page page, nil, "Avatar was copied from the gravatar of the e-mail address"
    click_on 'Save'
    check_this_page page, nil, "Your user entry \"#{users(:test_gravatar).login}\" has been changed."
  end
  test "create user with Gravatar" do
    visit new_user_url
    assert_selector "h1", text: "Create User Entry"
    fill_in 'user_login', with: users(:test_gravatar).login
    fill_in 'user_email', with: users(:test_gravatar).email
    fill_in 'user_password', with: 'abcDEF78'
    check_this_page page, nil, "Avatar was taken over by Gravatar"
    # no 'Save' as user with this email address exist already
  end

  test "upload avatar" do
    do_login
    check_page page, 'users/current/edit', nil, "Update User Entry"
    # click_on and attach_file are not working
    #   click_on 'Select file'
    #   attach_file('avatar-upload', '/tmp/face-smile.png', make_visible: true)
    # using hidden input field in bypassing Stimulus JS controller
    # image file `google-chrome.png` comes local from quote_chrome docker container
    find('form input[type="file"]', visible: false).set('/usr/share/icons/hicolor/256x256/apps/google-chrome.png')
    click_on 'Save'
    check_this_page page, nil, 'Your user entry "first_user" has been changed.'
  end
end
