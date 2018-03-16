require "application_system_test_case"

class CategoriesTest < ApplicationSystemTestCase

  test "category" do
    check_page page, "/categories", "h1", "Kategorie", 250
    assert_equal page.title, "Zitat-Service - Kategorien"
  end

  test "category_letter_a" do
    check_page page, "/categories/list_by_letter/A", "h1", "Kategorie", 200
    assert_equal page.title, "Zitat-Service - Kategorien die mit A beginnen"
  end

  test "category_not_letter" do
    check_page page, "/categories/list_by_letter/*", "h1", "Kategorie", 200
    assert_equal page.title, "Zitat-Service - Kategorien die mit * beginnen"
  end

  test "show category" do
    check_page page, category_url(Category.find_by_category('public_category')), "h1", "Kategorie", 200
    assert_equal page.title, "Zitat-Service - Kategorie public_category"
  end
  
  # /categories/new
  test "create category with login" do
    new_category_name = 'smile'
    visit login_url
    fill_in 'user_session_login', with: 'first_user'
    fill_in 'user_session_password', with: 'first_user_password'
    click_on 'Anmelden'
    check_page page, new_category_url, "h1", "Kategorie anlegen", 200
    fill_in 'category_name', with: new_category_name
    click_on 'Speichern'
    check_page page, category_url(Category.find_by_category(new_category_name)), "h1", "Kategorie", 200
  end
  # NICE delete own created category
  # NICE cannot delete category created by another user
  # NICE cannot delete category with quotations

  # /categorys/new
  test "new category without login" do
    check_page page, new_category_url, "h1", "Nicht erlaubt", 300
  end

end
