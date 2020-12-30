require "application_system_test_case"

class AuthorsTest < ApplicationSystemTestCase

  # /authors
  test "author" do
    check_page page, authors_url, "h1", "Autor"
    assert_equal page.title, "Zitat-Service - Autoren"
  end

  # /authors/list_by_letter/A
  test "author letter a" do
    check_page page, "/authors/list_by_letter/A", "h1", "Autor"
    assert_equal page.title, "Zitat-Service - Autoren die mit A beginnen"
    
    # slow performance seen with user w/o admin rights logged in
    visit login_url
    fill_in 'user_session_login', with: 'first_user'
    fill_in 'user_session_password', with: 'first_user_password'
    click_on 'Anmelden'
    check_page page, root_url, "a", "Logout"
    check_page page, "/authors/list_by_letter/M", "h1", "Autor"
    assert_equal page.title, "Zitat-Service - Autoren die mit M beginnen" 
  end

  # /authors/list_by_letter/*
  test "author not letter" do
    check_page page, "/authors/list_by_letter/*", "h1", "Autor"
    assert_equal page.title, "Zitat-Service - Autoren die mit * beginnen"
  end
  
  # e.g. /authors/1
  test "show author" do
    check_page page, author_url(Author.find_by_name('public_author')), "h1", "Autor"
    assert_equal page.title, "Zitat-Service - Autor public_author"
  end
  
  # /authors/new
  test "first or last name is needed" do
    visit login_url
    fill_in 'user_session_login', with: 'first_user'
    fill_in 'user_session_password', with: 'first_user_password'
    click_on 'Anmelden'
    check_page page, new_author_url, "h1", "Autor anlegen"
    click_on 'Speichern'
    check_this_page page, nil, "Vorname oder Nachname muss gesetzt sein"
  end

  # /authors/new
  test "create two authors with same name" do
    new_author_name = 'Hans'
    visit login_url
    fill_in 'user_session_login', with: 'first_user'
    fill_in 'user_session_password', with: 'first_user_password'
    click_on 'Anmelden'
    check_page page, new_author_url, "h1", "Autor anlegen"
    fill_in 'author_name', with: new_author_name
    click_on 'Speichern'
    check_page page, author_url(Author.find_by_name(new_author_name)), "h1", "Autor"
    # it is possible to have two authors with the same name
    check_page page, new_author_url, "h1", "Autor anlegen"
    fill_in 'author_name', with: new_author_name
    click_on 'Speichern'
    check_page page, author_url(Author.last), "h1", "Autor"
  end
  test "delete author" do
    new_author_name = 'XYZ'
    visit login_url
    fill_in 'user_session_login', with: 'first_user'
    fill_in 'user_session_password', with: 'first_user_password'
    click_on 'Anmelden'
    check_page page, new_author_url, "h1", "Autor anlegen"
    fill_in 'author_name', with: new_author_name
    click_on 'Speichern'
    au = author_url(Author.find_by_name(new_author_name))
    check_page page, au, "h1", "Autor"
    # delete
    visit "/authors/list_by_letter/X"
    accept_alert do
      find("img[title='Löschen']", match: :first).click
    end
    sleep 1 # there is still caching somewhere
    check_page page, au, "h1", "404 - Nicht gefunden"
  end
  # NICE cannot delete autho created by another user
  # NICE cannot delete author with quotations

  # /authors/new
  test "new author without login" do
    check_page page, new_author_url, "h1", "Nicht erlaubt"
  end

  test "edit own author" do
    visit login_url
    fill_in 'user_session_login', with: 'first_user'
    fill_in 'user_session_password', with: 'first_user_password'
    click_on 'Anmelden'
    check_page page, edit_author_url(1), "h1", "Author bearbeiten"
    fill_in 'author_name', with: 'jo!'
    click_on 'Speichern'
    check_this_page page, nil, 'Der Eintrag für den Autor .* wurde aktualisiert.'
    check_page page, quotation_url(1), nil, 'Name:[\s]+jo!' 
  end
  test "edit own author fails" do
    visit login_url
    fill_in 'user_session_login', with: 'first_user'
    fill_in 'user_session_password', with: 'first_user_password'
    click_on 'Anmelden'
    check_page page, edit_author_url(1), "h1", "Author bearbeiten"
    fill_in 'author_name', with: ''
    click_on 'Speichern'
    check_this_page page, nil, 'Vorname oder Nachname muss gesetzt sein'
  end

  test "admin needed to list not public authors" do
    check_page page, authors_list_no_public_url, nil, "Kein Administrator!"
  end
  test "list not public authors" do
    visit login_url
    fill_in 'user_session_login', with: 'admin_user'
    fill_in 'user_session_password', with: 'admin_user_password'
    click_on 'Anmelden'
    check_this_page page, nil, 'Hallo admin_user, schön dass Du da bist.'
    check_page page, authors_list_no_public_url, "h1", "Nicht-Öffentliche Autoren"
  end
end
