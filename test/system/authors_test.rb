require "application_system_test_case"

class AuthorsTest < ApplicationSystemTestCase

  # /authors
  test "authors" do
    check_page page, authors_url(locale :en), "h1", "Author"
    assert_equal "Zitat-Service – Authors", page.title
    check_this_page page, "h1", /.* Authors/
  end

  test "authors list ordered by author name" do
    check_page page, authors_url + "?order=authors", "h1", "Author"
    assert_equal "Zitat-Service – Authors", page.title
  end

  # /authors/list_by_letter/A
  test "author letter a" do
    check_page page, "/authors/list_by_letter/A", "h1", /Author.*, Last Name begins with the letter \"A\"/
    assert_equal "Zitat-Service – Authors, starting with A", page.title
    
    # slow performance seen with user w/o admin rights logged in
    do_login
    check_this_page page, "a", "Logout"
    check_page page, "/authors/list_by_letter/M", "h1", /Author.*, Last Name begins with the letter \"M\"/
    assert_equal "Zitat-Service – Authors, starting with M", page.title
  end

  # /authors/list_by_letter/*
  test "author not letter" do
    check_page page, "/authors/list_by_letter/*", "h1", /Author.*, Last Name begins not with an English letter/
    assert_equal "Zitat-Service – Authors, starting with *", page.title
  end
  
  # e.g. /authors/1
  test "show author" do
    check_page page, author_url(id: Author.i18n.find_by_name('Barbara')), "h1", "Author"
    assert_equal "Zitat-Service – Author Barbara", page.title
  end
  
  test "list and show non-public" do
    check_page page, authors_path(locale: :en), nil, "Public False Author"
    check_page page, "/en/authors/list_by_letter/P", nil, "Public False Author"
    check_page page, author_url(locale: :en, id: Author.i18n.find_by(name: "Public False Author Name")), "h1", "Author"
    
    do_login
    check_page page, authors_path(locale: :en), nil, "Public False Author"
    check_page page, "/en/authors/list_by_letter/P", nil, "Public False Author"
    check_page page, author_url(locale: :en, id: Author.i18n.find_by(name: "Public False Author Name")), "h1", "Author"
    
    do_login :admin_user, :admin_user_password
    check_page page, authors_path(locale: :en), nil, "Public False Author"
    check_page page, "/en/authors/list_by_letter/P", nil, "Public False Author"
    check_page page, author_url(locale: :en, id: Author.i18n.find_by(name: "Public False Author Name")), "h1", "Author"
  end

  # /authors/new
  test "first or last name is needed" do
    do_login
    check_page page, new_author_url, "h1", "Author create"
    click_on 'Save'
    check_this_page page, nil, "First name or last name must be set"
  end

  # /authors/new
  test "create two authors with same name" do
    new_author_name = 'Hans'
    do_login
    check_page page, new_author_url, "h1", "Author create"
    fill_in 'author_name', with: new_author_name
    click_on 'Save'
    check_this_page page, nil, "has been created" # make Capybara wait until the new author is created
    check_page page, author_url(id: Author.i18n.find_by_name(new_author_name)), "h1", "Author"
    # it is possible to have two authors with the same name?
    check_page page, new_author_url, "h1", "Author create"
    fill_in 'author_name', with: new_author_name
    click_on 'Save'
    check_this_page page, nil, "has been created" # make Capybara wait until the new author is created
    check_page page, author_url(id: Author.last), "h1", "Author"
  end

  test "delete author" do
    new_author_name = 'XYZ'
    do_login
    check_page page, new_author_url, "h1", "Author create"
    fill_in 'author_name', with: new_author_name
    click_on 'Save'
    check_this_page page, nil, "has been created", 200, true, 10000 # make Capybara wait until the new author is created
    au = author_url(id: Author.i18n.find_by_name(new_author_name))
    check_page page, au, "h1", "Author"
    # delete
    visit "/authors/list_by_letter/X"
    accept_alert do
      find("img[title='Delete']", match: :first).click
    end
    check_page page, au, "h1", /Page not found .* 404/
  end

  # NICE cannot delete author created by another user
  # NICE cannot delete author with quotations

  # /authors/new
  test "new author without login" do
    check_page page, new_author_url, "h1", /Access Denied .* 403/
  end

  test "edit own author" do
    do_login
    check_page page, edit_author_url(id: 1), "h1", "Edit author"
    fill_in 'author_name_en', with: 'yo!'
    click_on 'Save'
    check_this_page page, nil, /The entry for the author "yo!" has been updated./
    assert_equal "Zitat-Service – Author yo!", page.title 
  end
  test "edit own author fails" do
    do_login
    check_page page, edit_author_url(id: 1), "h1", "Edit author"
    fill_in 'author_name_en', with: ''
    click_on 'Save'
    check_this_page page, nil, 'First name or last name must be set'
  end

  test "admin needed to list not public authors" do
    check_page page, authors_list_no_public_url, nil, "Not an Administrator!"
    check_this_page page, nil, /Access Denied .* 403/
  end
  test "list not public authors" do
    do_login :admin_user, :admin_user_password
    check_this_page page, nil, 'Hello admin_user, nice to have you here.'
    check_page page, authors_list_no_public_url, "h1", "Not published Authors"
  end

  test "trailing slash" do
    check_page page, authors_url + '/', "h1", "Authors"
    assert_equal "Zitat-Service – Authors", page.title 
    # redirected URL w/o slash
    assert_equal page.current_url, authors_url
  end

  test "pagination with trailing slash" do
    url = authors_url + '?page=2/'
    check_page page, url, "h1", "Authors"
    check_this_page page, nil, "Actions"
    # redirected URL w/o slash
    assert_equal page.current_url, url.chop
  end

  test "pagination not found" do
    url = authors_url(locale: :en) + '?page=420000'
    check_page page, url, "h1", /Bad Request .* 400/
    # wrong URL have to be shown
    check_this_page page, nil, url
    check_page_source page, /href=".*quote\/issues/
  end

end
