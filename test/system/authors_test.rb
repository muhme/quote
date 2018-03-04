require "application_system_test_case"

class AuthorsTest < ApplicationSystemTestCase

  # /authors
  test "author" do
    check_page page, authors_url, "h1", "Autor", 250
  end

  # /authors/list_by_letter/A
  test "author_letter_a" do
    check_page page, "/authors/list_by_letter/A", "h1", "Autor", 200
  end

  # /authors/list_by_letter/*
  test "author_not_letter" do
    check_page page, "/authors/list_by_letter/*", "h1", "Autor", 200
  end
  
  # e.g. /author/1
  test "show author" do
    check_page page, author_url(Author.find_by_name('public_author')), "h1", "Autor", 200
  end
  
  # /authors/new
  test "new author with login" do
    visit login_url
    fill_in 'user_session_login', with: 'first_user'
    fill_in 'user_session_password', with: 'first_user_password'
    click_on 'Anmelden'
    check_page page, new_author_url, "h1", "Autor anlegen", 300
  end  

  # /authors/new
  test "new author without login" do
    check_page page, new_author_url, "h1", "Nicht erlaubt", 300
  end 

  #visit articles_path
 
  #click_on "New Article"
 
  #fill_in "Title", with: "Creating an Article"
  #fill_in "Body", with: "Created this article successfully!"
 
  #click_on "Create Article"
end
