require "application_system_test_case"

class CategoriesTest < ApplicationSystemTestCase

  test "category" do
    check_page page, "/categories", "h1", "Kategorie"
    assert_equal page.title, "Zitat-Service - Kategorien"
  end

  test "category letter a" do
    check_page page, "/categories/list_by_letter/A", "h1", "Kategorie"
    assert_equal page.title, "Zitat-Service - Kategorien die mit A beginnen"
  end

  test "category not letter" do
    check_page page, "/categories/list_by_letter/*", "h1", "Kategorie"
    assert_equal page.title, "Zitat-Service - Kategorien die mit * beginnen"
  end

  test "show category" do
    check_page page, category_url(Category.find_by_category('public_category')), "h1", "Kategorie"
    assert_equal page.title, "Zitat-Service - Kategorie public_category"
  end
  
  # /categories/new
  test "create and delete category" do
    new_category_name = 'smile'
    visit login_url
    fill_in 'user_session_login', with: 'first_user'
    fill_in 'user_session_password', with: 'first_user_password'
    click_on 'Anmelden'
    check_page page, new_category_url, "h1", "Kategorie anlegen"
    fill_in 'category_name', with: new_category_name
    click_on 'Speichern'
    cu = category_url(Category.find_by_category(new_category_name))
    check_page page, cu, "h1", "Kategorie"
    # delete
    visit "/categories/list_by_letter/S"
    accept_alert do
      find("img[title='Löschen']", match: :first).click
    end
    sleep 1 # there is still caching somewhere
    check_page page, cu, "h1", "404 - Nicht gefunden"
  end

  test "create new category fails" do
    visit login_url
    fill_in 'user_session_login', with: 'first_user'
    fill_in 'user_session_password', with: 'first_user_password'
    click_on 'Anmelden'
    check_page page, new_category_url, "h1", "Kategorie anlegen"
    fill_in 'category_name', with: ''
    click_on 'Speichern'
    check_this_page page, nil, "Category can't be blank"
  end

  # NICE cannot delete category created by another user
  # NICE cannot delete category with quotations

  # /categorys/new
  test "new category without login" do
    check_page page, new_category_url, "h1", "Nicht erlaubt"
  end

  test "edit own category" do
    visit login_url
    fill_in 'user_session_login', with: 'first_user'
    fill_in 'user_session_password', with: 'first_user_password'
    click_on 'Anmelden'
    check_page page, edit_category_url(1), "h1", "Kategorie bearbeiten"
    fill_in 'category_name', with: 'better name'
    click_on 'Speichern'
    check_this_page page, nil, 'Kategorie .* wurde aktualisiert.'
    check_page page, quotation_url(1), nil, 'Name:[\s]+better name' 
  end
  test "edit own category fails" do
    visit login_url
    fill_in 'user_session_login', with: 'first_user'
    fill_in 'user_session_password', with: 'first_user_password'
    click_on 'Anmelden'
    check_page page, edit_category_url(1), "h1", "Kategorie bearbeiten"
    fill_in 'category_name', with: ''
    click_on 'Speichern'
    check_this_page page, nil, "Category can't be blank"
  end

  test "admin needed to list not public categories" do
    check_page page, categories_list_no_public_url, nil, "Kein Administrator!"
  end
  test "list not public categories" do
    visit login_url
    fill_in 'user_session_login', with: 'admin_user'
    fill_in 'user_session_password', with: 'admin_user_password'
    click_on 'Anmelden'
    check_this_page page, nil, 'Hallo admin_user, schön dass Du da bist.'
    check_page page, categories_list_no_public_url, "h1", "Nicht-Öffentliche Kategorien"
  end

  test "trailing slash" do
    check_page page, categories_url + '/', "h1", "Kategorie"
    assert_equal page.title, "Zitat-Service - Kategorien"
    # redirected URL w/o slash
    assert_equal page.current_url, categories_url
  end

  test "pagination with trailing slash" do
    url = categories_url + '?page=2/'
    check_page page, url, "h1", "Kategorie"
    check_this_page page, nil, "Aktionen"
    # redirected URL w/o slash
    assert_equal page.current_url, url.chop
  end

  test "pagination not found" do
    url = categories_url + '?page=420000'
    check_page page, url, "h1", "404"
    # wrong URL have to be shown
    check_this_page page, nil, url
    check_this_page page, nil, "quote/issues"
  end

end
