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
  
end
