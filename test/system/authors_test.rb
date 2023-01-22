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
    do_login
    check_this_page page, "a", "Logout"
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
    check_page page, author_url(Author.find_by_name('Barbara')), "h1", "Autor"
    assert_equal page.title, "Zitat-Service - Autor Barbara"
  end
  
  # /authors/new
  test "first or last name is needed" do
    do_login
    check_page page, new_author_url, "h1", "Autor anlegen"
    click_on 'Speichern'
    check_this_page page, nil, "Vorname oder Nachname muss gesetzt sein"
  end

  # /authors/new
  test "create two authors with same name" do
    new_author_name = 'Hans'
    do_login
    check_page page, new_author_url, "h1", "Autor anlegen"
    fill_in 'author_name', with: new_author_name
    click_on 'Speichern'
    check_this_page page, "h1", "Autor" # do it before to have Capybara wait until and new author and url is existing
    check_page page, author_url(Author.find_by_name(new_author_name)), "h1", "Autor"
    # it is possible to have two authors with the same name
    check_page page, new_author_url, "h1", "Autor anlegen"
    fill_in 'author_name', with: new_author_name
    click_on 'Speichern'
    check_page page, author_url(Author.last), "h1", "Autor"
  end

  test "delete author" do
    new_author_name = 'XYZ'
    do_login
    check_page page, new_author_url, "h1", "Autor anlegen"
    fill_in 'author_name', with: new_author_name
    click_on 'Speichern'
    check_this_page page, "h1", "Autor" # do it before to have Capybara wait until and new author and url is existing
    au = author_url(Author.find_by_name(new_author_name))
    check_page page, au, "h1", "Autor"
    # delete
    visit "/authors/list_by_letter/X"
    accept_alert do
      find("img[title='Löschen']", match: :first).click
    end
    check_page page, au, "h1", "HTTP-Statuscode 404"
  end

  # NICE cannot delete author created by another user
  # NICE cannot delete author with quotations

  # /authors/new
  test "new author without login" do
    check_page page, new_author_url, "h1", /Zugriff wurde verweigert .* 403/
  end

  test "edit own author" do
    do_login
    check_page page, edit_author_url(1), "h1", "Author bearbeiten"
    fill_in 'author_name', with: 'jo!'
    click_on 'Speichern'
    check_this_page page, nil, /Der Eintrag für den Autor .* wurde aktualisiert/
    check_page page, quotation_url(1), nil, /Autor:.*jo!/ 
  end
  test "edit own author fails" do
    do_login
    check_page page, edit_author_url(1), "h1", "Author bearbeiten"
    fill_in 'author_name', with: ''
    click_on 'Speichern'
    check_this_page page, nil, 'Vorname oder Nachname muss gesetzt sein'
  end

  test "admin needed to list not public authors" do
    check_page page, authors_list_no_public_url, nil, "Kein Administrator!"
  end
  test "list not public authors" do
    do_login :admin_user, :admin_user_password
    check_this_page page, nil, 'Hallo admin_user, schön dass Du da bist.'
    check_page page, authors_list_no_public_url, "h1", "Nicht-Öffentliche Autoren"
  end

  test "trailing slash" do
    check_page page, authors_url + '/', "h1", "Autor"
    assert_equal page.title, "Zitat-Service - Autoren"
    # redirected URL w/o slash
    assert_equal page.current_url, authors_url
  end

  test "pagination with trailing slash" do
    url = authors_url + '?page=2/'
    check_page page, url, "h1", "Autor"
    check_this_page page, nil, "Aktionen"
    # redirected URL w/o slash
    assert_equal page.current_url, url.chop
  end

  test "pagination not found" do
    url = authors_url + '?page=420000'
    check_page page, url, "h1", "404"
    # wrong URL have to be shown
    check_this_page page, nil, url
    check_page_source page, /href=".*quote\/issues/
  end

end
