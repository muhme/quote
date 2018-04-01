require "application_system_test_case"

class AuthorsTest < ApplicationSystemTestCase

  # /authors
  test "author" do
    check_page page, authors_url, "h1", "Autor", 250
    assert_equal page.title, "Zitat-Service - Autoren"
  end

  # /authors/list_by_letter/A
  test "author_letter_a" do
    check_page page, "/authors/list_by_letter/A", "h1", "Autor", 200
    assert_equal page.title, "Zitat-Service - Autoren die mit A beginnen"
    
    # slow performance seen with user w/o admin rights logged in
    visit login_url
    fill_in 'user_session_login', with: 'first_user'
    fill_in 'user_session_password', with: 'first_user_password'
    click_on 'Anmelden'
    
  end

  # /authors/list_by_letter/*
  test "author_not_letter" do
    check_page page, "/authors/list_by_letter/*", "h1", "Autor", 200
    assert_equal page.title, "Zitat-Service - Autoren die mit * beginnen"
    check_page page, "/authors/list_by_letter/A", "h1", "Autor", 200
    assert_equal page.title, "Zitat-Service - Autoren die mit A beginnen"
  end
  
  # e.g. /authors/1
  test "show author" do
    check_page page, author_url(Author.find_by_name('public_author')), "h1", "Autor", 200
    assert_equal page.title, "Zitat-Service - Autor public_author"
  end
  
  # /authors/new
  test "create author with login" do
    new_author_name = 'Hans'
    visit login_url
    fill_in 'user_session_login', with: 'first_user'
    fill_in 'user_session_password', with: 'first_user_password'
    click_on 'Anmelden'
    check_page page, new_author_url, "h1", "Autor anlegen", 300
    fill_in 'author_name', with: new_author_name
    click_on 'Speichern'
    check_page page, author_url(Author.find_by_name(new_author_name)), "h1", "Autor", 300
  end
  # NICE delete own created author
  # NICE cannot delete autho created by another user
  # NICE cannot delete author with quotations

  # /authors/new
  test "new author without login" do
    check_page page, new_author_url, "h1", "Nicht erlaubt", 300
  end

end
